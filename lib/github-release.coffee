# Handle the GitHub "release" event
#
# Usage:
#
# require('../lib/github-release')(robot, room, data)
#
# OR
#
# github_release = require '../lib/github-release'
# github_release robot, room, data

module.exports = (robot, room, payload) ->
  return if not payload.release?
  return if not payload.action?
  return if not payload.action == "published"

  repo = payload.repository.full_name

  user_name = payload.release.author.login
  user_url = payload.release.author.html_url

  release_name = if payload.release.name != "" then payload.release.name else "#{repo} #{payload.release.tag_name}"
  release_url = payload.release.html_url
  release_body = payload.release.body

  ts = new Date payload.release.published_at
  ts = new Date ts.getTime()
  ts = Math.floor(ts.getTime() / 1000)

  attachment =
    attachments: [
      fallback: "[#{repo}] New release #{release_name} created by #{user_name}: #{release_url}"
      color: "#4183C4"
      pretext: "[<https://github.com/#{repo}|#{repo}>] New release <#{release_url}|#{release_name}> created by <#{user_url}|#{user_name}>"
      author_name: "#{repo} (GitHub)"
      author_link: "https://github.com/#{repo}"
      author_icon: "https://a.slack-edge.com/2fac/plugins/github/assets/service_36.png"
      title: release_name
      title_link: release_url
      text: release_body
      fields: [
        {
          title: "Repository"
          value: "<https://github.com/#{repo}|#{repo}>"
          short: true
        }
        {
          title: "Released By"
          value: "<#{user_url}|#{user_name}>"
          short: true
        }
      ]
      footer: "GitHub"
      footer_icon: "https://a.slack-edge.com/2fac/plugins/github/assets/service_36.png"
      ts: ts
    ]

  robot.send room: room, attachment
