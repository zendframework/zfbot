# Default error handler for bot
#
# Replies with the error if a response is provided.
#
# In all cases, it logs the error. If a room is provided, it will message
# that room with the error, so that the admin can see the issues.

class ErrorHandler
  constructor: (@robot, @room) ->

  listen: (err, res) ->
    if res
      # If we have a response, reply
      res.reply "Oops! That's an error: #{err.message}"

    errorMessage = "ERROR:\n"
    errorMessage += if err.stack? then err.stack else err.toString()

    # Log the error
    @robot.logger.error errorMessage

    return if not @room

    # Message the configured room
    format = (line) -> return "    " + line
    errorMessage = errorMessage.split("\n").map(format).join("\n")

    @robot.messageRoom @room, errorMessage

module.exports = ErrorHandler
