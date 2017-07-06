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

  robot.respond /twitter clear/i, (msg) -> tweetStream.clear(msg)
  robot.respond /twitter follow (.*)$/i, (msg) -> tweetStream.follow(msg)
  robot.respond /twitter list/i, (msg) -> tweetStream.list(msg)
  robot.respond /twitter unfollow (.*)$/i, (msg) -> tweetStream.unfollow(msg)
  robot.respond /twitter untrack (.*)$/i, (msg) -> tweetStream.untrack(msg)
  robot.respond /twitter track (.*)$/i, (msg) -> tweetStream.track(msg)
  robot.brain.on "loaded", (data) -> tweetStream.load(data)

  robot.on "tweet", (tweet_data) -> tweeter.tweet(tweet_data)
