# Handle an incoming Discourse topic

discourse_category = require "./discourse-category"

module.exports = (robot, room, discourse_url, payload) ->
  return if not payload?.topic?
  topic = payload.topic

  return if not topic.visible
  return if topic.draft?

  action = if topic.posts_count == 1 then "created" else "edited"

  url = "#{discourse_url}/t/#{topic.slug}/#{topic.id}"

  ts = if action == "created" then topic.created_at else topic.last_posted_at
  ts = new Date ts
  ts = Math.floor(ts.getTime() / 1000)

  user_name = topic.details.created_by.username
  user_link = "<#{discourse_url}/u/#{user_name}|#{user_name}>"

  category = discourse_category(robot, topic.category_id)

  fields = [
    {
      title: "Category"
      value: "<#{discourse_url}/c/#{category.slug}|#{category.name}>"
      short: true
    }
    {
      title: "Posted by"
      value: user_link
      short: true
    }
  ]

  if topic.tags.length > 0
    tags = []
    topic.tags.forEach (tag) => tags.push "- <#{discourse_url}/tags/#{tag}|#{tag}>"
    fields.push {
      title: "Tags"
      value: tags.join "\n"
    }

  attachment =
    attachments: [
      color: "#295473"
      fallback: "Discourse: Topic #{action} in #{category.name}: #{url}"
      author_name: "Discourse"
      author_link: discourse_url
      author_icon: "https://slack-imgs.com/?c=1&o1=wi16.he16&url=https%3A%2F%2Fdiscourse-meta.s3-us-west-1.amazonaws.com%2Foriginal%2F3X%2Fc%2Fb%2Fcb4bec8901221d4a646e45e1fa03db3a65e17f59.png"
      title: "[#{category.name}] Topic #{action}: #{topic.fancy_title}"
      title_link: url
      text: "Topic #{action} in category <#{discourse_url}/c/#{category.slug}|#{category.name}>: <#{url}|#{topic.fancy_title}>"
      fields: fields
      footer: "Discourse"
      footer_icon: "https://slack-imgs.com/?c=1&o1=wi16.he16&url=https%3A%2F%2Fdiscourse-meta.s3-us-west-1.amazonaws.com%2Foriginal%2F3X%2Fc%2Fb%2Fcb4bec8901221d4a646e45e1fa03db3a65e17f59.png"
      ts: ts
    ]

  robot.send room: room, attachment
