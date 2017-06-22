# Handle the GitHub "pull_request_review_comment" event
#
# Usage:
#
# require('../lib/github-pull-request-review-comment')(robot, room, data)
#
# OR
#
# github_pull_request_review_comment = require # '../lib/github-pull-request-review-comment'
# github_pull_request_review_comment robot, room, data

module.exports = (robot, room, payload) ->
  return if not payload.comment?
  return if not payload.action?
  return if not payload.action == "created"

  content = payload.comment.body
  url = payload.comment.html_url

  repo = payload.repository.full_name
  user_name = payload.comment.user.login
  user_url = payload.comment.user.html_url
  pr_id = payload.pull_request.number
  pr_title = payload.pull_request.title
  pr_url = payload.pull_request.html_url

  ts = new Date payload.comment.created_at
  ts = new Date ts.getTime()
  ts = Math.floor(ts.getTime() / 1000)

  attachment =
    attachments: [
      fallback: "[#{repo}] #{user_name} commented on pull request ##{pr_id}: #{url}"
      color: "#FAD5A1"
      pretext: "[<https://github.com/#{repo}|#{repo}>] <#{user_url}|#{user_name}> commented on <#{pr_url}|##{pr_id} #{pr_title}>"
      author_name: "#{repo} (GitHub)"
      author_link: "https://github.com/#{repo}"
      author_icon: "https://a.slack-edge.com/2fac/plugins/github/assets/service_36.png"
      title: "Pull request review comment created for #{repo}##{pr_id} #{pr_title}"
      title_link: pr_url
      text: content
      fields: [
        {
          title: "Repository"
          value: "<https://github.com/#{repo}|#{repo}>"
          short: true
        }
        {
          title: "Commenter"
          value: "<#{user_url}|#{user_name}>"
          short: true
        }
      ]
      footer: "GitHub"
      footer_icon: "https://a.slack-edge.com/2fac/plugins/github/assets/service_36.png"
      ts: ts
    ]

  robot.send room: room, attachment
