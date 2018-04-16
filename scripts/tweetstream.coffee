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
#   hubot tweet <message> - Tweet a message from the configured twitter account
#   hubot retweet <id> - Retweet a message from the configured twitter account. Provide either a tweet ID, or a tweet URI.
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
#   Matthew Weier O'Phinney

Tweeter = require '../lib/twitter-tweeter'
TweetStream = require '../lib/twitter-tweetstream'
Twit = require('twit')

module.exports = (robot) ->

  AUTH =
    consumer_key: process.env.HUBOT_TWITTER_CONSUMER_KEY
    consumer_secret: process.env.HUBOT_TWITTER_CONSUMER_SECRET
    access_token: process.env.HUBOT_TWITTER_ACCESS_TOKEN_KEY
    access_token_secret: process.env.HUBOT_TWITTER_ACCESS_TOKEN_SECRET

  twit = new Twit(AUTH)
  tweeter = new Tweeter(robot, twit)
  tweetStream = new TweetStream(robot, twit, process.env.HUBOT_TWITTER_CLEAN_SUBSCRIPTIONS?)

  robot.respond /twitter clear/i, id: "authorize", (msg) -> tweetStream.clear(msg)
  robot.respond /twitter follow (.*)$/i, id: "authorize", (msg) -> tweetStream.follow(msg)
  robot.respond /twitter list/i, (msg) -> tweetStream.list(msg)
  robot.respond /twitter unfollow (.*)$/i, id: "authorize", (msg) -> tweetStream.unfollow(msg)
  robot.respond /twitter untrack (.*)$/i, id: "authorize", (msg) -> tweetStream.untrack(msg)
  robot.respond /twitter track (.*)$/i, id: "authorize", (msg) -> tweetStream.track(msg)

  robot.respond /tweet (.*)$/i, id: "authorize", (msg) ->
    text = msg.match[1]
    if text.length > 280
      msg.send "That tweet message is too long (#{text.length} characters); please shorten it to 280 characters."
      return
    tweeter.tweet { status: text }, (data) =>
      msg.send "Tweet sent! https://twitter.com/#{data.screen_name}/status/#{data.id_str}"

  robot.respond /retweet (.*)$/i, id: "authorize", (msg) ->
    tweet_id = msg.match[1]
    tweeter.retweet tweet_id, (data) =>
      msg.send "Message retweeted! https://twitter.com/#{data.screen_name}/status/#{data.id_str}"

  robot.brain.on "loaded", (data) -> tweetStream.load(data)

  robot.on "tweet", (tweet_data) -> tweeter.tweet(tweet_data)
