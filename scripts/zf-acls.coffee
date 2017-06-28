# Description:
#   Zend Framework SlackBot ACLs: add and remove users from ACL whitelist,
#   allowing them to perform other bot actions.
#
# Commands:
#   hubot acl allow <user> - Add a user to the whitelist.
#   hubot acl deny <user> - Remove a user from the whitelist.
#   hubot acl list - List users in the whitelist.
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

ZfAcl = require '../lib/zf-acl'

module.exports = (robot) ->

  user_whitelist = []
  if process.env.HUBOT_ZF_ACL_USER_WHITELIST
    user_whitelist = process.env.HUBOT_ZF_ACL_USER_WHITELIST
    user_whitelist = user_whitelist.split ','

  acl = new ZfAcl robot, user_whitelist, process.env.HUBOT_VERBOSE?

  robot.respond /acl list/i, (msg) -> acl.list(msg)
  robot.respond /acl allow (.*)$/i, (msg) -> acl.allow(msg)
  robot.respond /acl deny (.*)$/i, (msg) -> acl.deny(msg)
  robot.brain.on "loaded", (data) -> acl.load(data)
