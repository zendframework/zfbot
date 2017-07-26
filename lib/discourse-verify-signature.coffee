# Verify a Discourse webhook payload signature

crypto = require "crypto"

module.exports = (req, secret) ->
  return false if not req.headers?
  return false if not req.headers.hasOwnProperty "x-discourse-event-signature"

  header = req.headers["x-discourse-event-signature"]
  signature = if header.match /^sha256\=/ then header.substring 7 else header

  compare = crypto.createHmac('sha256', secret).update(req.rawBody, 'utf-8').digest('hex')
  return signature == compare.toString()
