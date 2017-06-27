# Description:
#   Follow Discourse topics.
#
# Commands:
#   hubot discourse follow <category slug> - Start watching the specified Discourse category (by slug; e.g. "contributors", "questions/expressive") in the current room.
#   hubot discourse unfollow <category slug> - Stop watching the specified Discourse category (by slug; e.g. "contributors", "questions/expressive") in the current room.
#   hubot discourse status - List which Discourse categories are being watched in this room.
#   hubot discourse clear - Unwatch all Discourse categories in this room.
#
# Configuration:
#
# The following environment variables are required.
#
# HUBOT_DISCOURSE_URL:            Base URL to the Discourse installation
# HUBOT_DISCOURSE_USER:           Discourse username for API
# HUBOT_DISCOURSE_API_KEY:        API key associated with user
# HUBOT_DISCOURSE_POLL_INTERVAL:  Interval for polling
#
# Examples:
#   hubot discourse follow contributors
#   hubot discourse follow questions/expressive
#   hubot discourse unfollow questions/expressive
#   hubot discourse status
#   hubot discourse clear
#
# Author:
#   Matthew Weier O'Phinney

Discourse = require 'discourse-api'
DiscourseListener = require '../lib/discourse-listener'

Discourse.prototype.latestTopics = (category, callback) ->
  @getCategoryLatestTopic category, {}, (error, body, httpCode) ->
    payload = JSON.parse(body)
    error = payload if payload.errors?
    callback(error, payload, httpCode)

module.exports = (robot) ->

  discourse_url = process.env.HUBOT_DISCOURSE_URL
  discourse_user = process.env.HUBOT_DISCOURSE_USER
  discourse_api_key = process.env.HUBOT_DISCOURSE_API_KEY
  poll_interval = process.env.HUBOT_DISCOURSE_POLL_INTERVAL ? 300000

  listener = new DiscourseListener(robot, new Discourse(discourse_url, discourse_api_key, discourse_user), discourse_url, poll_interval)

  robot.respond(/discourse follow (.*)$/i, (msg) -> listener.follow msg, msg.match[1])
  robot.respond(/discourse unfollow (.*)$/i, (msg) -> listener.unfollow msg, msg.match[1])
  robot.respond(/discourse status\s*$/i, (msg) -> listener.list msg)
  robot.respond(/discourse clear\s*$/i, (msg) -> listener.clear msg)
  robot.brain.on("loaded", (data) -> listener.load(data))
