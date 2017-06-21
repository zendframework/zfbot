# Handle the GitHub "issue_comment" event
#
# Usage:
#
# require('../lib/github-issue-comment')(robot, room, data)
#
# OR
#
# github_issue_comment = require '../lib/github-issue-comment'
# github_issue_comment robot, room, data

module.exports = (robot, room, payload) ->
  return if not payload.issue?
  return if not payload.action?
  return if not payload.action == "created"

  repo = payload.repository.full_name
  comment = payload.comment.body
  comment_url = payload.comment.html_url
  user_name = payload.comment.user.login

  issue_id = payload.issue.number
  issue_title = payload.issue.title
  issue_type = if payload.issue.pull_request? then "pull request" else "issue"

  ts = new Date payload.comment.created_at
  ts = new Date ts.getTime()
  ts = Math.floor(ts.getTime() / 1000)

  attachment =
    attachments: [
      fallback: "[#{repo}] New comment by #{user_name} on #{issue_type} [##{issue_id} #{issue_title}](#{comment_url})"
      color: "#FAD5A1"
      pretext: "[#{repo}] New comment by #{user_name} on #{issue_type} [##{issue_id} #{issue_title}](#{comment_url})"
      author_name: "#{repo} (GitHub)"
      author_link: "https://github.com/#{repo}"
      author_icon: "https://a.slack-edge.com/2fac/plugins/github/assets/service_36.png"
      text:  comment
      footer: "GitHub"
      footer_icon: "https://a.slack-edge.com/2fac/plugins/github/assets/service_36.png"
      ts: ts
    ]

  robot.send room: room, attachment
