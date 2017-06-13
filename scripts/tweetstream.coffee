# Description:
#  Subscribe to tweets matching keywords
#
# Commands:
#   hubot twitter track <keyword> - Start watching a keyword
#   hubot twitter untrack <keyword> - Stop watching a keyword
#   hubot twitter follow <screen_name> - Start following tweets from @screen_name
#   hubot twitter unfollow <screen_name> - Stop following tweets from @screen_name
#   hubot twitter list - Get the watched keywords and users list in current room
#   hubot twitter clear - Stop watching all keywords and users in current room
#
# Configuration:
#
# The following environment variables are required. You will need to create an application at https://dev.twitter.com
#
# HUBOT_TWITTER_CONSUMER_KEY
# HUBOT_TWITTER_CONSUMER_SECRET
# HUBOT_TWITTER_ACCESS_TOKEN_KEY
# HUBOT_TWITTER_ACCESS_TOKEN_SECRET
#
# The following environment variables are optional:
#
# HUBOT_TWITTER_CLEAN_SUBSCRIPTIONS: Clear all subscriptions at boot time.
#
# Examples:
#   hubot twitter track github
#   hubot twitter follow nodejs
#
# Author:
#   Christophe Hamerling
#   Matthew Weier O'Phinney (user verification)

Twit = require('twit')
_ = require('lodash')
authorize = require('../lib/authorize')

module.exports = (robot) ->

  TYPES =
    TRACK: "track"
    FOLLOW: "follow"

  AUTH =
    consumer_key: process.env.HUBOT_TWITTER_CONSUMER_KEY
    consumer_secret: process.env.HUBOT_TWITTER_CONSUMER_SECRET
    access_token: process.env.HUBOT_TWITTER_ACCESS_TOKEN_KEY
    access_token_secret: process.env.HUBOT_TWITTER_ACCESS_TOKEN_SECRET

  class Stream
    type: null
    room: null
    track: null
    follow: null
    screen_name: null
    tweet_stream: null

    toFollow: (room, follow, id) ->
      @type = TYPES.FOLLOW
      @screen_name = follow
      @follow = id
      @room = room

    toTrack: (room, track) ->
      @type = TYPES.TRACK
      @track = track
      @room = room

  class TweetStream
    constructor: (@robot, @twit, @clear_subs) ->

    BRAIN_TWITTER_STREAMS: "twitter"
    loaded: false
    streams: []

    saveTweetStream: (stream) ->
      @streams.push(stream)
      found = _.find(@robot.brain.get(@BRAIN_TWITTER_STREAMS), (subscription) ->
        switch stream.type
          when TYPES.FOLLOW
            return subscription.follow == stream.follow && subscription.room == stream.room && subscription.type == stream.type
          when TYPES.TRACK
            return subscription.track == stream.track && subscription.room == stream.room && subscription.type == stream.type
      )

      return if found

      toSave = null
      switch stream.type
        when TYPES.FOLLOW
          toSave =
            type: TYPES.FOLLOW
            room: stream.room
            follow: stream.follow
            screen_name: stream.screen_name
        when TYPES.TRACK
          toSave =
            type: TYPES.TRACK
            room: stream.room
            track: stream.track
        else
          return

      savedStreams = @robot.brain.get(@BRAIN_TWITTER_STREAMS)
      savedStreams.push(toSave)
      @robot.brain.set(@BRAIN_TWITTER_STREAMS, savedStreams)

    formatTimeString: (date) ->
      ampm  = "am"
      hours = date.getHours()
      ampm  = "pm" if hours > 11
      hours = hours - 12 if hours > 12
      hours = 12 if hours == 0
      minutes = date.getMinutes()
      minutes = "0" + minutes if minutes < 10

      "#{hours}:#{minutes} #{ampm}"

    initializeStream: (stream) ->
      filter = {}

      switch stream.type
        when TYPES.FOLLOW
          filter.follow = stream.follow
        when TYPES.TRACK
          filter.track = stream.track
        else
          return

      tweetStream = @twit.stream('statuses/filter', filter)
      tweetStream.on 'tweet', (tweet) =>
        return if stream.type == TYPES.FOLLOW && tweet.user.id_str != stream.follow
        ts = new Date(tweet.created_at)
        ts = new Date(ts.getTime())
        created = @formatTimeString ts

        attachment =
          attachments: [
            color: "#00ACED"
            fallback: "@#{tweet.user.screen_name} at #{created}: https://twitter.com/#{tweet.user.screen_name}/status/#{tweet.id_str}"
            author_name: "#{tweet.user.screen_name} @#{tweet.user.name}"
            author_link: "https://twitter.com/#{tweet.user.screen_name}/status/#{tweet.id_str}"
            author_icon: "#{tweet.user.profile_image_url_https}"
            text: tweet.text
            footer: "Twitter"
            footer_icon: "https://a.slack-edge.com/66f9/img/services/twitter_128.png"
            ts: Math.floor(ts.getTime() / 1000)
          ]

        if tweet.entities?.media? && tweet.entities.media.length > 0
          tweet.entities.media.forEach (media) ->
            attachment.attachments.push({
              color: "#00ACED"
              fallback: media.media_url_https
              text: media.media_url_https
            })

        @robot.send room: stream.room, attachment

      @robot.logger.info("Started a new twitter stream", filter)
      stream.tweet_stream = tweetStream
      @saveTweetStream(stream)

    restoreSubscription: (subscription) ->
      return @robot.logger.error('Can not restore subscription; missing room or type', subscription) if !subscription || !subscription.room || !subscription.type

      switch subscription.type
        when TYPES.FOLLOW
          return @robot.logger.error('Can not restore follow subscription; missing follow identifier or screen name', subscription) if !subscription.screen_name || !subscription.follow
          stream = new Stream()
          stream.toFollow(subscription.room, subscription.screen_name, subscription.follow)
          @initializeStream(stream)
        when TYPES.TRACK
          return @robot.logger.error('Can not restore track subscription; missing tracking string', subscription) if !subscription.track
          stream = new Stream()
          stream.toTrack(subscription.room, subscription.track)
          @initializeStream(stream)

    restoreSubscriptions: ->
      subscriptions = @robot.brain.get(@BRAIN_TWITTER_STREAMS)
      return @robot.brain.set(@BRAIN_TWITTER_STREAMS, []) if !subscriptions?.length?
      @restoreSubscription(subscription) for subscription in subscriptions

    getIdFromScreenName: (screen_name, callback) ->
      @twit.get('users/lookup', {screen_name}, (err, response) ->
        return callback(err) if err

        return callback(new Error("User not found")) if !response?.length?

        callback(null, response[0].id_str)
      )

    load: (data) ->
      # this loaded event is sent on each robot.brain.set, skip it after initial load
      return if @loaded

      @loaded = true

      if @clear_subs then @robot.brain.set(@BRAIN_TWITTER_STREAMS, []) else @restoreSubscriptions()

    clear: (msg) ->
      return msg.send "You are not allowed to do that." if !authorize(@robot, msg)

      match = (subscription) -> subscription.room == msg.message.room

      toRemove = _.remove(@streams, match)

      return msg.send "No subscription in this room" if !toRemove.length

      subscription.stream.stop() for subscription in toRemove

      savedStreams = @robot.brain.get(@BRAIN_TWITTER_STREAMS)
      @robot.brain.set(@BRAIN_TWITTER_STREAMS, _.remove(savedStreams, match))

      msg.send "Unsubscribed from all"

    follow: (msg) ->
      return msg.send "You are not allowed to do that." if !authorize(@robot, msg)

      screen_name = msg.match[1]
      @getIdFromScreenName(screen_name, (err, id) =>
        return @robot.logger.error("Can not get twitter user id from #{screen_name}", err) if err

        stream = new Stream()
        stream.toFollow(msg.message.room, screen_name, id)
        @initializeStream(stream)
      )

    list: (msg) ->
      currentRoomTags = @streams
        .filter((subscription) -> subscription.room == msg.message.room)
        .map((subscription) ->
          if subscription.room == msg.message.room
            switch subscription.type
              when TYPES.FOLLOW then return "- From user @#{subscription.screen_name}"
              when TYPES.TRACK then return "- Matching #{subscription.track}"
        )

      return msg.send("No subscriptions. Hint: Type 'twitter track/follow XXX' to listen to XXX related tweets in current room") if not currentRoomTags.length

      currentRoomTags.unshift("I am listening to tweets with the following criteria:")
      msg.send currentRoomTags.join("\n")

    unsubscribe: (match) ->
      toRemove = _.remove(@streams, match)
      return false if !toRemove.length

      subscription.stream.stop() for subscription in toRemove

      savedStreams = @robot.brain.get(@BRAIN_TWITTER_STREAMS)
      @robot.brain.set(@BRAIN_TWITTER_STREAMS, _.remove(savedStreams, match))
      true

    unfollow: (msg) ->
      return msg.send "You are not allowed to do that." if !authorize(@robot, msg)

      screen_name = msg.match[1]

      msg.send("I stopped following tweets from '#{screen_name}'") if @unsubscribe((subscription) => subscription.type == TYPES.FOLLOW && subscription.screen_name == screen_name && subscription.room == msg.message.room)

    untrack: (msg) ->
      return msg.send "You are not allowed to do that." if !authorize(@robot, msg)

      word = msg.match[1]
      msg.send("I have stopped tracking tweets matching '#{word}'") if @unsubscribe((subscription) => subscription.type == TYPES.TRACK && subscription.track == word && subscription.room == msg.message.room)

    track: (msg) ->
      return msg.send "You are not allowed to do that." if !authorize(@robot, msg)
      stream = new Stream()
      stream.toTrack(msg.message.room, msg.match[1])
      @initializeStream(stream)

  tweetStream = new TweetStream(robot, new Twit(AUTH), process.env.HUBOT_TWITTER_CLEAN_SUBSCRIPTIONS?)

  robot.respond(/twitter clear/i, (msg) -> tweetStream.clear(msg))
  robot.respond(/twitter follow (.*)$/i, (msg) -> tweetStream.follow(msg))
  robot.respond(/twitter list/i, (msg) -> tweetStream.list(msg))
  robot.respond(/twitter unfollow (.*)$/i, (msg) -> tweetStream.unfollow(msg))
  robot.respond(/twitter untrack (.*)$/i, (msg) -> tweetStream.untrack(msg))
  robot.respond(/twitter track (.*)$/i, (msg) -> tweetStream.track(msg))
  robot.brain.on("loaded", (data) -> tweetStream.load(data))
