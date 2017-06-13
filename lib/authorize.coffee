# Verify ACLs for a given user
#
# Import the module and assign it to a function:
# verify = require('../lib/authorize')
#
# Later:
# return msg.send "You are not allowed to do that." if !authorize(@robot, msg)

module.exports = (robot, msg) ->
  users = robot.brain.get("zf-acl")
  return true if 1 > users.length
  msg.envelope.user.name in users
