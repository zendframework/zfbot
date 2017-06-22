# Handle the GitHub "pull_request" event
#
# Usage:
#
# require('../lib/github-pull-request')(robot, room, data)
#
# OR
#
# github_pull_request = require '../lib/github-pull-request'
# github_pull_request robot, room, data

module.exports = (robot, room, payload) ->
  return if not payload.pull_request?
  return if not payload.action?
  return if not payload.action in ["opened", "closed", "reopened"]

  action = payload.action
  action = "merged" if action == "closed" and payload.pull_request.merged

  repo = payload.repository.full_name
  user_name = payload.pull_request.user.login
  user_url = payload.pull_request.user.html_url
  pr_id = payload.pull_request.number
  pr_title = payload.pull_request.title
  pr_url = payload.pull_request.html_url
  pr_content = if action == "created" then payload.pull_request.body else ""

  switch action
    when "opened" then ts = new Date payload.pull_request.created_at
    when "closed" then ts = new Date payload.pull_request.closed_at
    when "reopened" then ts = new Date payload.pull_request.updated_at
    when "merged" then ts = new Date payload.pull_request.merged_ad

  ts = new Date ts.getTime()
  ts = Math.floor(ts.getTime() / 1000)

  attachment =
    attachments: [
      fallback: "[#{repo}] Pull request #{action} by #{user_name}: #{pr_url}"
      color: "#E3E4E6"
      pretext: "[#{repo}] Pull request #{action} by #{user_name}"
      author_name: "#{repo} (GitHub)"
      author_link: "https://github.com/#{repo}"
      author_icon: "https://a.slack-edge.com/2fac/plugins/github/assets/service_36.png"
      title: "Pull request #{action}: #{repo}##{pr_id} #{pr_title}"
      title_link: pr_url
      text: pr_content
      fields: [
        {
          title: "Repository"
          value: "<https://github.com/#{repo}|#{repo}>"
          short: true
        }
        {
          title: "Reporter"
          value: "<#{user_url}|#{user_name}>"
          short: true
        }
        {
          title: "Status"
          value: action
          short: true
        }
      ]
      footer: "GitHub"
      footer_icon: "https://a.slack-edge.com/2fac/plugins/github/assets/service_36.png"
      ts: ts
    ]

  robot.send room: room, attachment
