# Description:
#   Listen to Discourse webhooks. Listens for "topic" and "post" hooks, passing
#   them on to dedicated webhook scripts. Middleware is registered that verifies
#   the incoming payload's X-Discourse-Event-Signature against a known secret to
#   validate the origin of the webhook payload.
#
#   Register webhooks via the Discourse settings UI. When you do, use URIs of
#   the format "/discourse/{ROOM_ID}/(topic|post)", where {ROOM_ID} is the
#   identifier for the Slack room to which the webhook should post messages (you
#   can retrieve that by right-clicking a room, copying the URL, and extracting
#   the final path segment).
#
# Configuration:
#
# The following environment variables are required.
#
# HUBOT_DISCOURSE_URL: Base URL to the Discourse installation
# HUBOT_DISCOURSE_SECRET: Shared secret between Discourse instance and webhook # (for verifying signatures)
#
# Author:
#   Matthew Weier O'Phinney

bodyParser = require 'body-parser'
discourse_post = require "../lib/discourse-post"
discourse_topic = require "../lib/discourse-topic"
verify_signature = require "../lib/discourse-verify-signature"

module.exports = (robot) ->

  discourse_url = process.env.HUBOT_DISCOURSE_URL
  discourse_secret = process.env.HUBOT_DISCOURSE_SECRET

  # In order to calculate signatures, we need to shove the JSON body
  # parser to the top of the stack and have it set the raw request body
  # contents in the request when done parsing.
  robot.router.stack.unshift {
    route: "/discourse"
    handle: bodyParser.json {
      verify: (req, res, buf, encoding) ->
        req.rawBody = buf
    }
  }

  robot.router.post '/discourse/:room/:event', (req, res) ->
    room = req.params.room
    event = req.params.event

    if event not in ["topic", "post"]
      res.send 203, "Unrecognized event #{event}"
      robot.logger.error "[Discourse] Unrecognized event '#{event}' was pinged"
      return

    if not verify_signature(req, discourse_secret)
      res.send 203, "Invalid or missing signature"
      robot.logger.error "Invalid payload submitted to /discourse/#{room}/#{event}; signature invalid"
      return

    # We can accept it now, so return a response immediately
    res.send 202

    data = req.body

    # Now, we need to switch on the event, and determine what message to send
    # to the room.
    switch event
      when "topic"
        discourse_topic robot, room, discourse_url, data
      when "post"
        discourse_post robot, room, discourse_url, data
