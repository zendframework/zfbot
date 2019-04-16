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

DocsBuild = require '../lib/docs-build'

module.exports = (robot) ->
  bodyParser = require 'body-parser'

  robot.logger.info "docs listener registered"

  user  = process.env.HUBOT_DOCS_GITHUB_USER
  email = process.env.HUBOT_DOCS_GITHUB_EMAIL
  token = process.env.HUBOT_DOCS_GITHUB_TOKEN
  docs = new DocsBuild robot, user, email, token

  robot.respond /docs build (.*)$/i, id: "authorize", (msg) ->
    repo = msg.match[1]
    docs.build repo, msg

  robot.on "build-success", (data) -> docs.build(data.repo, false)

  # In order to calculate signatures, we need to shove the JSON body
  # parser to the top of the stack and have it set the raw request body
  # contents in the request when done parsing.
  robot.router.stack.unshift {
    route: "/docs"
    handle: bodyParser.json {
      verify: (req, res, buf, encoding) ->
        req.rawBody = buf
    }
  }

  robot.router.post '/docs', (req, res) ->
    # First we check for
    if not req.headers? or not req.headers.hasOwnProperty "authorization"
      res.send 401, "Unauthorized"
      return

    header = req.headers['authorization']
    if not header.match /^bearer [a-f0-9]+/i
      res.send 400, "Client Error: invalid authentication type"
      return

    receivedToken = header.substring 7
    if not receivedToken or receivedToken != process.env.HUBOT_DOCS_API_TOKEN
      res.send 403, "Forbidden"
      return

    data = req.body

    if not data.repo? or not data.repo.match /zendframework\/[a-z0-9]+/
      res.send 422, "Missing or malformed required repo property"
      return

    # We can now accept it; return a response immediately, and then process
    res.send 202

    msg = {
      send: (msg) ->
        robot.logger.error msg
    }

    docs.build data.repo, msg
