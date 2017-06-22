# Handle the GitHub "pull_request_review" event
#
# Usage:
#
# require('../lib/github-pull-request-review')(robot, room, data)
#
# OR
#
# github_pull_request_review = require '../lib/github-pull-request-review'
# github_pull_request_review robot, room, data

module.exports = (robot, room, payload) ->
  return if not payload.review?
  return if not payload.action?
  return if not payload.action in ["submitted", "dismissed"]

  state = payload.action
  state = "approved" if state == "submitted" and payload.review.state.match(/approved/i)
  state = "requested changes on" if state == "submitted" and payload.review.state.match(/pending/i)
  state = "commented on" if state == "submitted" and payload.review.state.match(/commented/i)
  content = payload.review.body

  repo = payload.repository.full_name
  user_name = payload.review.user.login
  user_url = payload.review.user.html_url
  pr_id = payload.pull_request.number
  pr_title = payload.pull_request.title
  pr_url = payload.pull_request.html_url

  ts = new Date payload.review.submitted_at
  ts = new Date ts.getTime()
  ts = Math.floor(ts.getTime() / 1000)

  attachment =
    attachments: [
      fallback: "[#{repo}] #{user_name} #{state} pull request ##{pr_id}: #{pr_url}"
      color: "#E3E4E6"
      pretext: "[<https://github.com/#{repo}|#{repo}>] <#{user_url}|#{user_name}> #{state} <#{pr_url}|##{pr_id} #{pr_title}>"
      author_name: "#{repo} (GitHub)"
      author_link: "https://github.com/#{repo}"
      author_icon: "https://a.slack-edge.com/2fac/plugins/github/assets/service_36.png"
      title: "Pull request review #{state} for #{repo}##{pr_id} #{pr_title}"
      title_link: pr_url
      text: content
      fields: [
        {
          title: "Repository"
          value: "<https://github.com/#{repo}|#{repo}>"
          short: true
        }
        {
          title: "Reviewer"
          value: "<#{user_url}|#{user_name}>"
          short: true
        }
        {
          title: "Status"
          value: state
          short: true
        }
      ]
      footer: "GitHub"
      footer_icon: "https://a.slack-edge.com/2fac/plugins/github/assets/service_36.png"
      ts: ts
    ]

  robot.send room: room, attachment
