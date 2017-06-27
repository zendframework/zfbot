# Class representing a twitter stream being followed by hubot.

TYPES = require "./twitter-types"

class TwitterStream
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

module.exports = TwitterStream
