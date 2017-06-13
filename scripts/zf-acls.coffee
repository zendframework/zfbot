# Description:
#   Zend Framework SlackBot ACLs: add and remove users from ACL whitelist,
#   allowing them to perform other bot actions.
#
# Commands:
#   hubot acl allow <user> - Add a user to the whitelist.
#   hubot acl deny <user>  - Remove a user from the whitelist.
#   hubot acl list         - List users in the whitelist.
#
# Configuration:
#
# The following environment variables are optional:
#
# HUBOT_ZF_ACL_USER_WHITELIST: Comma-separated list of users allowed by default.
# HUBOT_VERBOSE: Flag indicating whether or not to be verbose in output.
#
# Examples:
#
#   hubot acl allow akrabat
#   hubot acl deny ocramius
#   hubot acl list
#
# Author:
#   Matthew Weier O'Phinney

module.exports = (robot) ->

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
      users = @robot.brain.get(@BRAIN_ACL_WHITELIST)
      return @robot.brain.set(@BRAIN_ACL_WHITELIST, @user_whitelist) if !users?.length?
      @user_whitelist.push(user) for user in users

    verify: (msg) ->
      return true if 1 > @user_whitelist.length
      msg.envelope.user.name in @user_whitelist

    allow: (msg) ->
      return msg.send "You are not allowed to do that." if !@verify(msg)

      user = msg.match[1]
      return msg.send("User #{user} is already in the ACL whitelist.") if user in @user_whitelist

      @user_whitelist.push(user)
      @robot.brain.set(@BRAIN_ACL_WHITELIST, @user_whitelist)

      msg.send "User #{user} added to ACL whitelist."

    deny: (msg) ->
      return msg.send "You are not allowed to do that." if !@verify(msg)

      user = msg.match[1]
      return msg.send "User #{user} is not in the ACL whitelist." if user not in @user_whitelist

      @user_whitelist = _.remove(@user_whitelist, (item) -> item == user)
      @robot.brain.set(@BRAIN_ACL_WHITELIST, @user_whitelist)

      msg.send "User #{user} removed from ACL whitelist."

    list: (msg) ->
      return msg.send "You are not allowed to do that." if !@verify(msg)

      if 0 == @user_whitelist.length
        msg.send "No users in whitelist!"
        return

      msg.send "Found #{@user_whitelist.length} users in whitelist:"
      @user_whitelist.forEach (user) ->
        msg.send "- #{user}"

    verifyUser: (user) ->
      console.log "Verifying user", user
      return true if 1 > @user_whitelist.length
      console.log "Whitelist is non-empty"
      return true if user.user in @user_whitelist
      console.log "User is not in whitelist"
      error =
        message: "User #{user.user} does not have permissions for #{user.context}"
        user: user.user
        context: user.context
      throw error


  user_whitelist = []
  if process.env.HUBOT_ZF_ACL_USER_WHITELIST
    user_whitelist = process.env.HUBOT_ZF_ACL_USER_WHITELIST
    user_whitelist = user_whitelist.split(',')

  acl = new ZfAcl(robot, user_whitelist, process.env.HUBOT_VERBOSE?)

  robot.respond /acl list/i, (msg) -> acl.list(msg)
  robot.respond /acl allow (.*)$/i, (msg) -> acl.allow(msg)
  robot.respond /acl deny (.*)$/i, (msg) -> acl.deny(msg)
  robot.brain.on "loaded", (data) -> acl.load(data)
  robot.brain.on "acl.verify", (user) -> acl.verifyUser(user)
