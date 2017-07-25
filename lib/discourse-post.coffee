# Handle an incoming Discourse post (comment)

formatter = require "slackify-html"

module.exports = (robot, room, discourse_url, payload) ->
  return if not payload?.post?
  post = payload.post

  return if post.hidden
  return if post.deleted_at

  action = if post.created_at == post.updated_at then "created" else "edited"

  url = "#{discourse_url}/t/#{post.topic_slug}/#{post.topic_id}/#{post.id}"

  ts = if action == "created" then post.created_at else post.updated_at
  ts = new Date ts
  ts = Math.floor(ts.getTime() / 1000)

  user_link = "<#{discourse_url}/u/#{post.username}|#{post.name}>"
  topic_link = "<#{discourse_url}/t/#{post.topic_slug}/#{post.topic_id}|#{post.topic_title}>"

  fields = [
    {
      title: "In reply to"
      value: topic_link
      short: true
    }
    {
      title: "Posted by"
      value: user_link
      short: true
    }
  ]

  attachment =
    attachments: [
      color: "#295473"
      fallback: "Discourse: Comment #{action} for #{post.topic_title}: #{url}"
      author_name: "Discourse"
      author_link: discourse_url
      author_icon: "https://slack-imgs.com/?c=1&o1=wi16.he16&url=https%3A%2F%2Fdiscourse-meta.s3-us-west-1.amazonaws.com%2Foriginal%2F3X%2Fc%2Fb%2Fcb4bec8901221d4a646e45e1fa03db3a65e17f59.png"
      title: "Comment #{action} for #{post.topic_title} by #{post.name}"
      title_link: url
      text: formatter post.cooked
      fields: fields
      footer: "Discourse"
      footer_icon: "https://slack-imgs.com/?c=1&o1=wi16.he16&url=https%3A%2F%2Fdiscourse-meta.s3-us-west-1.amazonaws.com%2Foriginal%2F3X%2Fc%2Fb%2Fcb4bec8901221d4a646e45e1fa03db3a65e17f59.png"
      ts: ts
    ]

  robot.send room: room, attachment
