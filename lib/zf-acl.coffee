# Class for managing bot ACLs for the ZF slack

class ZfAcl
  constructor: (@robot, @user_whitelist = [], @verbose = false) ->

  BRAIN_ACL_WHITELIST: "zf-acl"
  loaded: false

  load: (data) ->
    # this loaded event is sent on each robot.brain.set, skip it after initial load
    return if @loaded

    @loaded = true
    @restoreAllowedUsers()

  restoreAllowedUsers: ->
    users = @robot.brain.get @BRAIN_ACL_WHITELIST
    return @robot.brain.set(@BRAIN_ACL_WHITELIST, @user_whitelist) if !users?.length?
    @user_whitelist.push(user) for user in users

  verify: (msg) ->
    return true if 1 > @user_whitelist.length
    msg.envelope.user.name in @user_whitelist

  allow: (msg) ->
    return msg.send "You are not allowed to do that." if !@verify(msg)

    user = msg.match[1]
    return msg.send("User #{user} is already in the ACL whitelist.") if user in @user_whitelist

    @user_whitelist.push user
    @robot.brain.set @BRAIN_ACL_WHITELIST, @user_whitelist

    msg.send "User #{user} added to ACL whitelist."

  deny: (msg) ->
    return msg.send "You are not allowed to do that." if !@verify(msg)

    user = msg.match[1]
    return msg.send "User #{user} is not in the ACL whitelist." if user not in @user_whitelist

    @user_whitelist = _.remove @user_whitelist, (item) -> item == user
    @robot.brain.set @BRAIN_ACL_WHITELIST, @user_whitelist

    msg.send "User #{user} removed from ACL whitelist."

  list: (msg) ->
    return msg.send "You are not allowed to do that." if !@verify(msg)

    if 0 == @user_whitelist.length
      msg.send "No users in whitelist!"
      return

    users = ["Found #{@user_whitelist.length} users in whitelist:"]
    @user_whitelist.forEach (user) -> users.push "- #{user}"
    msg.send users.join("\n")

module.exports = ZfAcl
