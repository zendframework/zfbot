# WORKPLAN

## [X] ACLs

Create an ACL system that will be used by all plugins, and which exposes
commands for manipulating the ACLs. It should:

The plugin would expose a method to allow verifying if the user emitting the
message is in the whitelist, returning a boolean

The chatbot script would expose the following:

- `acl allow <user>`: Add a user to the whitelist
- `acl deny <user>`: Remove a user from the whitelist
- `acl list`: List whitelisted users

Only somebody _already in the whitelist_ may perform any of the above.

### Problems

- Unsure how to export functionality from one script to another, making
  verification harder.
  
  Events (`robot.on` in the ACL module + `robot.emit` in modules needing
  verification) will not work, as the return values of listeners are discarded.
  However, if the verification were to raise an exception, we could wrap the
  emit in a try/catch and return early:

  ```coffeescript
  try
    @robot.emit "acl.verify", msg.envelope.user
  catch err
    return msg.send "You are not allowed to do that."
  ```

  It's more verbose, but would work.

  Another option is to have the new ACL system include a "verify" method or
  similar in what it exports:

  ```coffeescript
  exports = module.exports = {}

  exports.verify = (user) ->
    return true if 1 > user_whitelist.length
    user.name in user_whitelist
  ```

  The problem with this approach is that I don't know if it will work. All
  other scripts export a _function_, accepting the _robot_. As such, what
  happens when we return an object? Can we make it act as a constructor?
  If so, will each script get the _same_ instance, or _different_ instances? If
  the latter, it's untenable.

### Final solution

Wrote a library function, `authorize`, that accepts the robot and message as
arguments. It then pulls the ACL from the robot.brain, and checks the envelope
user against it.

## [ ] Twitter

- [x] Rewrite to use the new ACL system, and thus remove the ACL bits it contained.
- [x] Rewrite to use attachments (see github.coffee) to display tweets. (? Check to
  see how they are displayed before doing this.)
- [x] Fix issue with tracks not persisting
- [ ] Fix issue with unsub/untrack
  Currently, it appears that all subscriptions EXCEPT what you wish to unfollow
  are removed from the brain.

## [x] Github

This is the trickiest integration, as PuSH requires TLS, **and** github doesn't
have great detail on what the payloads look like, making emulation and testing
harder.

- Events of interest:
  - issue_comment
  - issues
  - pull_request_review_comment
  - pull_request_review
  - pull_request
  - release
  - status
- [x] Write functionality for _subscribing_ to a PuSH endpoint
  - [x] Requires ENV vars for:
    - [x] a github username
    - [x] an OAuth2 personal access token associated with the username
    - [x] a shared secret key for request verification purposes
    - [x] the public-accessible, TLS-enabled URI for the server
  - [x] Requires following input:
    - [x] channel name
    - [ ] org/owner
    - [ ] repo
    - [x] or combine the last two, and split them on receipt
  - [x] Makes a request for each event we're interested in to
    https://api.github.com/hub, passing the appropriate GitHub topic URL (which
    requires the org/owner and repo) and the hubot callback URL, and the shared
    secret key. This MUST append `.json` to the GitHub URI to ensure we get a
    JSON payload pushed to us!
  - [x] Stores the channel name and repository in the robot.brain
- [x] Write functionality for _unsubscribing_ to a PuSH endpoint
  - [x] Same ENV requirements as for subscribing, minus the shared secret
  - [x] Same INPUT requirements as for subscribing
  - [x] Does the same request as for subscribing, but `hub.mode` will be
    `unsubscribe`
  - [x] Removes the robot.brain entry for the given channel/repository combo
- [x] Write routes for the events we want to listen to.
  - [x] Verify the push came from github, by grabbing the signature from
    X-Hub-Signature, and comparing that value to a SHA1 HMAC of the response
    body (usin the shared secret).
  - [x] Evaluate payloads received for items of interest
  - [x] Post details of items of interest to the configured room
    - [x] Use message attachments to allow creating custom look-and-feel for
      different events.
- [x] Write listeners for:
  - [x] `github follow <repo>`: subscribe to the given repository in this channel
  - [x] `github unfollow <repo>`: unsubscribe from the given repo in this channel
  - [x] `github list`: list subscriptions in this channel
  - [x] `github clear`: clear any subscriptions from this channel

## [ ] Github Stretch Goals

- [ ] Write functionality for the `push` event that, on a push to master, triggers
  a build of the documentation. 
- [ ] Write functionality for the `release` event that updates the release RSS
  feed and/or notifies twitter.

## Discourse

### Webhooks

Ping the Discourse team about the webhooks. If they allow it:

- Write a route that accepts Discourse events, and sends messages to slack. Will
  likely need to capture a few days of events first to see what we can send.

### Polling

If they do not answer, or answer in the negative:

- Remove the ACL functionality and use the new ACL module
- Fix the polling issue, and ensure it does not emit the latest item on every
  poll.
- Potentially poll more frequently

## Nginx

- Create Docker configuration for building an nginx web server with an SSL
  certificate generated by letsencrypt, and which acts as a proxy to the node
  server.

## Deployment to DigitalOcean

- Register a domain or setup a subdomain, and setup DO with the bot.
