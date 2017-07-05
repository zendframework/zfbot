# Description:
#   Default error handler.

ErrorHandler = require "../lib/error-handler"

module.exports = (robot) ->
  HUBOT_ERROR_ROOM = if process.env.HUBOT_ERROR_ROOM? then process.env.HUBOT_ERROR_ROOM else false

  handler = new ErrorHandler robot, HUBOT_ERROR_ROOM
  robot.error (err, res) -> handler.listen err, res
