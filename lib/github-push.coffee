# Un/Subscribe from/to Github PubSubHubbub events for a repository
#
# Simple class exposing two methods, subscribe and unsubscribe. Uses the
# hubbaseurl to form the callback for each event, the provided secret
# for specifying an encryption salt for verifying signatures of pushed
# event payloads, and the OAuth2 personal access token to use with the
# API.
#
# Usage:
#
# githubPush = require('../lib/github-push')
# subscriptions = new githubPush(
#   robot,
#   "https://sub.example.com",
#   HUBOT_GITHUB_TOKEN,
#   HUBOT_GITHUB_SALT
# )
#
# subscriptions.subscribe(msg, "weierophinney/github_push")
# subscriptions.unsubscribe(msg, "weierophinney/github_push")

fetch = require 'node-fetch'
formurlencoded = require 'form-urlencoded'
crypto = require 'crypto'

class GithubPush
  constructor: (@robot, @hubbaseurl, @token, @secret) ->

  BRAIN_GITHUB_REPOS: "github"
  PUSH_URI: "https://api.github.com/hub"

  events: [
    "issues",
    "issue_comment",
    "pull_request",
    "pull_request_review",
    "pull_request_review_comment",
    "release",
    "status"
  ]

  subscribe: (msg, repo) ->
    room = msg.message.room
    @events.forEach (event) =>
      data =
        "hub.mode": "subscribe"
        "hub.secret": @secret
        "hub.topic": "https://github.com/#{repo}/events/#{event}.json"
        "hub.callback": "#{@hubbaseurl}/#{room}/#{event}"
      fetch(@PUSH_URI, {
        method: "POST"
        body: formurlencoded(data)
        headers:
          Authorization: "token #{@token}"
          "Content-Type": "application/x-www-form-urlencoded"
      }).then((res) =>
        if not res.ok
          msg.send "Error subscribing to #{repo} event #{event}; please check the logs"
          @robot.logger.error "Error subscribing to #{repo} event #{event}: #{err}\n#{err.stack}"
          return

        repos = @robot.brain.get @BRAIN_GITHUB_REPOS
        repos = [] if not repos?.length?
        repos.push({
          room: room
          repo: repo
        })
        @robot.brain.set @BRAIN_GITHUB_REPOS, repos

        msg.send "Successfully subscribed to #{repo} #{event} event"
      ).catch((err) =>
        msg.send "Error occurred while subscribing to #{repo} event #{event}; check the logs"
        @robot.logger.error "Error subscribing to #{repo} event #{event}: #{err}\n#{err.stack}"
      );

  unsubscribe: (msg, repo) ->
    room = msg.message.room
    @events.forEach (event) =>
      data =
        "hub.mode": "unsubscribe"
        "hub.topic": "https://github.com/#{repo}/events/#{event}.json"
        "hub.callback": "#{@hubbaseurl}/#{room}/#{event}"
      fetch(@PUSH_URI, {
        method: "POST"
        body: formurlencoded(data)
        headers:
          Authorization: "token #{@token}"
          "Content-Type": "application/x-www-form-urlencoded"
      }).then((res) =>
        if not res.ok
          msg.send "Error unsubscribing to #{repo} event #{event}; please check the logs"
          @robot.logger.error "Error unsubscribing to #{repo} event #{event}: #{err}\n#{err.stack}"
          return

        repos = @robot.brain.get @BRAIN_GITHUB_REPOS
        repos = [] if not repos?.length?
        repos = repos.filter (compare) =>
          compare.repo != repo and compare.room != room
        @robot.brain.set @BRAIN_GITHUB_REPOS, repos

        msg.send "Successfully unsubscribed from #{repo} event #{event}"
      ).catch((err) =>
        msg.send "Error occurred while unsubscribing from #{repo} event #{event}; check the logs"
        @robot.logger.error "Error unsubscribing from #{repo} event #{event}: #{err}\n#{err.stack}"
      );

  list: (msg) ->
    room = msg.message.room
    entries = @robot.brain.get @BRAIN_GITHUB_REPOS
    entries = [] if not entries?.length?
    entries = entries.filter (entry) -> entry.room == room

    reduce = (unique, entry) ->
      unique.push entry.repo if entry.repo not in unique
      unique

    repos = entries.reduce reduce, []
    repos = repos.map (repo) -> "- <https://github.com/#{repo}|#{repo}>"

    return msg.send "No github subscriptions in this room" if not repos.length

    repos.unshift "This room subscribes to the following github repositories:"
    msg.send repos.join("\n")

  clear: (msg) ->
    room = msg.message.room
    entries = @robot.brain.get @BRAIN_GITHUB_REPOS
    entries = [] if not entries?.length?
    entries.forEach (entry) =>
      return if entry.room != room
      @unsubscribe msg, entry.repo

  verifySignature: (req) ->
    return false if not req.headers?
    return false if not req.headers.hasOwnProperty "x-hub-signature"
    signature = req.headers["x-hub-signature"]
    compare = crypto.createHmac('sha1', @secret).update(req.rawBody).digest('hex')
    return signature == compare.toString()

  verifyRoom: (repo, room) ->
    repos = @robot.brain.get @BRAIN_GITHUB_REPOS
    repos = [] if not repos?.length?
    repos = repos.filter (test) =>
      return test.repo == repo and test.room == room
    return true if repos.length

module.exports = GithubPush
