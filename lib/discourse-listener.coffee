# Class for listening to a Discourse instance

_ = require 'lodash'
authorize = require './authorize'

class DiscourseListener
  constructor: (@robot, @discourse, @discourse_url, @poll_interval) ->

  BRAIN_DISCOURSE_WATCH: "discourse"
  loaded: false
  watches: []

  load: (data) ->
    # this loaded event is sent on each robot.brain.set, skip it after initial load
    return if @loaded

    @loaded = true
    @restore()

  restore: () ->
    watches = @robot.brain.get @BRAIN_DISCOURSE_WATCH
    return @robot.brain.set(@BRAIN_DISCOURSE_WATCH, @watches) if !watches?.length?
    watches.forEach (watch) =>
      return if not watch.category?
      watch.last_poll = @lastPoll()
      @initializeWatch watch
      @watches.push watch

  watch: (category, room) ->
    found = _.find @watches, (watch) -> watch.room == room and watch.category == category
    return false if found

    watch =
      category: category
      room: room
      watcher: null
      last_poll: @lastPoll()

    @initializeWatch watch
    @watches.push watch

    watches = @robot.brain.get(@BRAIN_DISCOURSE_WATCH) ? []
    watches.push {category, room}
    @robot.brain.set @BRAIN_DISCOURSE_WATCH, watches
    true

  unwatch: (category, room) ->
    match = (watch) -> room == watch.room and category == watch.category
    found = _.find @watches, match
    return false if not found

    for watch in found
      clearInterval(watch.watcher) if watch.watcher?
      _.remove @watches, match
      watches = @robot.brain.get(@BRAIN_DISCOURSE_WATCH) ? []
      changed = _.remove watches, match
      @robot.brain.set(@BRAIN_DISCOURSE_WATCH, watches) if changed.length
      @robot.logger.info "Stopped watching Discourse category '#{category}' in room '#{room}'"

    true

  initializeWatch: (watch) ->
    watch.watcher = =>
      @discourse.latestTopics watch.category, (error, payload) =>
        return @robot.logger.error("Error retrieving latest discourse topics for category '#{category}' in room '#{room}'", error) if error

        found = false

        for topic in payload.topic_list.topics
          # Need to get last time of polling from database, and only emit
          # if the time on this topic is later than then. Additionally, do
          # not emit if the topic is not visible, or if it has no
          # "last_posted_at" field!
          continue if not topic.visible
          continue if not topic.last_posted_at?

          posted_at = new Date topic.last_posted_at
          continue if posted_at <= watch.last_poll

          found = posted_at if not found or found < posted_at

          ts = Math.floor(posted_at.getTime() / 1000)
          is_comment = topic.highest_post_number > 1
          action = if is_comment then "Comment posted" else "Topic created"
          category_url = "#{@discourse_url}/c/#{watch.category}"
          topic_url = "#{@discourse_url}/t/#{topic.slug}/#{topic.id}/#{topic.highest_post_number}"
          user = @getAuthor topic.last_poster_username, payload.users

          fields = [
            {
              title: "Category"
              value: "<#{category_url}|#{watch.category}>"
              short: true
            }
          ]

          switch user
            when false
              text = "#{action} in <#{category_url}|#{watch.category}>:\n<#{topic_url}|#{topic.title}>"
            else
              fields.push {
                title: "Posted by"
                value: "<#{@discourse_url}/u/#{user.username}|#{user.username}>"
                short: true
              }
              text = "#{action} in <#{category_url}|#{watch.category}> by <#{@discourse_url}/u/#{user.username}|#{user.username}>:\n<#{topic_url}|#{topic.title}>"

          tags = []
          topic.tags.forEach (tag) => tags.push "- <#{@discourse_url}/tags/#{tag}|#{tag}>"

          if tags.length > 0
            fields.push {
              title: "Tags"
              value: tags.join "\n"
            }

          attachment =
            attachments: [
              color: "#295473"
              fallback: "Discourse: #{action} in #{watch.category}: #{topic_url}"
              author_name: "Discourse"
              author_link: @discourse_url
              author_icon: "https://slack-imgs.com/?c=1&o1=wi16.he16&url=https%3A%2F%2Fdiscourse-meta.s3-us-west-1.amazonaws.com%2Foriginal%2F3X%2Fc%2Fb%2Fcb4bec8901221d4a646e45e1fa03db3a65e17f59.png"
              title: "[#{watch.category}] #{topic.title}"
              title_link: topic_url
              text: text
              fields: fields
              footer: "Discourse"
              footer_icon: "https://slack-imgs.com/?c=1&o1=wi16.he16&url=https%3A%2F%2Fdiscourse-meta.s3-us-west-1.amazonaws.com%2Foriginal%2F3X%2Fc%2Fb%2Fcb4bec8901221d4a646e45e1fa03db3a65e17f59.png"
              ts: ts
            ]

          @robot.send room: watch.room, attachment

        watch.last_poll = found if found

    setInterval watch.watcher, @poll_interval
    @robot.logger.info "Started watching Discourse category '#{watch.category}' in room '#{watch.room}'"
    watch.watcher()

  lastPoll: () ->
    new Date(Date.now() - @poll_interval)

  getAuthor: (poster, users) ->
    for user in users
      continue if poster != user.username
      return user
    return false

  follow: (msg, category) ->
    return msg.send "You are not allowed to do that." if !authorize(@robot, msg)
    switch @watch(category, msg.message.room)
      when true then return msg.send "Now watching Discourse category #{category}"
      when false then return msg.send "Already watching Discourse category #{category}"

  unfollow: (msg, category) ->
    return msg.send "You are not allowed to do that." if !authorize(@robot, msg)
    switch @unwatch(category, msg.message.room)
      when true then return msg.send "No longer watching Discourse category #{category}"
      when false then return msg.send "Discourse category #{category} was not being watched"

  list: (msg) ->
    return msg.send "You are not allowed to do that." if !authorize(@robot, msg)
    watches = []
    for watch in @watches
      watches.push "- <#{@discourse_url}/c/#{watch.category}|#{watch.category}>" if msg.message.room == watch.room
    return msg.send "Not watching discourse in this room" if not watches.length
    watches.unshift "Watching the following Discourse categories in this room:"
    msg.send watches.join "\n"

  clear: (msg) ->
    return msg.send "You are not allowed to do that." if !authorize(@robot, msg)

    @watches.forEach (watch) ->
      return if watch.room != msg.message.room
      @unfollow msg, watch.category

module.exports = DiscourseListener
