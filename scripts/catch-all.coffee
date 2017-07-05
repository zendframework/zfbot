# Description:
#   Catch all unhandled messages.

module.exports = (robot) ->
  robot.catchAll (msg) ->
    regexp = new RegExp "^(@?#{robot.alias}:?|#{robot.name})", "i"
    matches = msg.message.text.match regexp

    return if matches == null or matches.length == 0

    msg.reply "I am unable to comply."
    msg.finish()
