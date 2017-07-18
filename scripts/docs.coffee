# Description:
#  Documentation build automation
#
# Commands:
#   hubot docs build <repo> - Start building docs for the given repository
#
# Configuration:
#
# The following environment variables are required. You will need to create an application at https://dev.twitter.com
#
# HUBOT_DOCS_GITHUB_USER
# HUBOT_DOCS_GITHUB_EMAIL
# HUBOT_DOCS_GITHUB_TOKEN
#
# Examples:
#   hubot docs build zendframework/zend-expressive
#
# Author:
#   Matthew Weier O'Phinney

authorize = require '../lib/authorize'
DocsBuild = require '../lib/docs-build'

module.exports = (robot) ->
  robot.logger.info "docs listener registered"

  user  = process.env.HUBOT_DOCS_GITHUB_USER
  email = process.env.HUBOT_DOCS_GITHUB_EMAIL
  token = process.env.HUBOT_DOCS_GITHUB_TOKEN
  docs = new DocsBuild robot, user, email, token

  robot.respond /docs build (.*)$/i, (msg) ->
    return msg.send "You are not allowed to do that." if !authorize(robot, msg)
    repo = msg.match[1]
    docs.build repo, msg

  robot.on "build-success", (data) -> docs.build(data.repo, false)
