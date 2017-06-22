# Description:
#   Subscribe repositories to github events.
#
# Commands:
#   hubot github follow <repo> - Start following the specified repository in this channel; should be in the form <ownerOrOrg>/<repo>
#   hubot github unfollow <repo> - Stop following the specified repository in this channel
#   hubot github list - List repositories followed in this channel
#   hubot github clear - Stop following all repositories in this channel
#
# Configuration:
#
# The following environment variables are required.
#
# HUBOT_GITHUB_TOKEN: Authentication token to use with GitHub API
# HUBOT_GITHUB_CALLBACK_URL_BASE: Base URL for event callbacks.
# HUBOT_GITHUB_CALLBACK_SECRET: Secret to use for new subscriptions; used to verify event payloads.
# HUBOT_GITHUB_DEFAULT_ORG: Default user/org to use when not provided with a repository specification
#
# Examples:
#   hubot github follow zendframework/zend-stdlib
#   hubot github unfollow zendframework/zend-expressive
#   hubot github list
#
# Author:
#   Matthew Weier O'Phinney

module.exports = (robot) ->
  authorize = require '../lib/authorize'
  github_push = require '../lib/github-push'
  github_issues = require '../lib/github-issues'
  github_issue_comment = require '../lib/github-issue-comment'
  github_pull_request = require '../lib/github-pull-request'
  github_pull_request_review = require '../lib/github-pull-request-review'
  github_pull_request_review_comment = require '../lib/github-pull-request-review-comment'
  github_release = require '../lib/github-release'
  github_status = require '../lib/github-status'

  HUBOT_GITHUB_TOKEN = process.env.HUBOT_GITHUB_TOKEN
  HUBOT_GITHUB_DEFAULT_ORG = if process.env.HUBOT_GITHUB_DEFAULT_ORG? then process.env.HUBOT_GITHUB_DEFAULT_ORG else "zendframework"
  HUBOT_GITHUB_CALLBACK_URL_BASE = process.env.HUBOT_GITHUB_CALLBACK_URL_BASE
  HUBOT_GITHUB_CALLBACK_SECRET = process.env.HUBOT_GITHUB_CALLBACK_SECRET

  githubSub = new github_push robot, HUBOT_GITHUB_CALLBACK_URL_BASE, HUBOT_GITHUB_TOKEN, HUBOT_GITHUB_CALLBACK_SECRET

  robot.respond /github follow (.*)$/i, (msg) ->
    return msg.send "You are not allowed to do that." if !authorize(robot, msg)
    repo = msg.match[1]
    if not repo.match(/^[^/]+\/[^/]+$/)
      repo = "#{HUBOT_GITHUB_DEFAULT_ORG}/#{repo}"
    githubSub.subscribe msg, repo

  robot.respond /github unfollow (.*)$/i, (msg) ->
    return msg.send "You are not allowed to do that." if !authorize(robot, msg)
    repo = msg.match[1]
    if not repo.match(/^[^/]+\/[^/]+$/)
      repo = "#{HUBOT_GITHUB_DEFAULT_ORG}/#{repo}"
    githubSub.unsubscribe msg, repo

  robot.respond /github list/i, (msg) ->
    githubSub.list msg

  robot.respond /github clear/i, (msg) ->
    return msg.send "You are not allowed to do that." if !authorize(robot, msg)
    githubSub.clear msg

  robot.router.post '/github/:room/:event', (req, res) ->
    if event not in githubSub.events
      robot.emit 'error', "Unrecognized github event '#{event}' was pinged"
      res.sendStatus 203
      return

    if not githubSub.verifySignature(req)
      robot.emit 'error', "Invalid payload submitted to /github/#{req.params.room}/#{req.params.event}; signature invalid"
      res.sendStatus 203
      return

    room = req.params.room
    event = req.params.event
    data = JSON.parse req.body

    if not githubSub.verifyRoom(data.repository.full_name, room)
      robot.emit 'error', "Invalid payload submitted to /github/#{req.params.room}/#{req.params.event}; no repo '#{data.repository.full_name}' hooks registered for this room"
      res.sendStatus 203
      return

    # Now, we need to switch on the event, and determine what message to send
    # to the room.
    switch event
      when "issues"
        github_issues robot, room, data
      when "issue_comment"
        github_issue_comment robot, room, data
      when "pull_request"
        github_pull_request robot, room, data
      when "pull_request_review"
        github_pull_request_review robot, room, data
      when "pull_request_review_comment"
        github_pull_request_review_comment robot, room, data
      when "release"
        github_release robot, room, data
      when "status"
        github_status robot, room, data, HUBOT_GITHUB_TOKEN

    res.sendStatus 202
