# Description:
#   Echo back who you currently are logged in as.
#
# Commands:
#   hubot whoami - Echo back who you are.
#
# Configuration:
#
# None.
#
# Examples:
#
#   hubot whoami
#
# Author:
#   Matthew Weier O'Phinney

module.exports = (robot) ->

  robot.respond /whoami/i, (msg) ->
    msg.send "You are #{msg.envelope.user.name}"
