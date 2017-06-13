# TODO

- [ ] discourse is not honoring last_poll correctly, and was emitting the latest
  item every time.
- [ ] travis integration (which could potentially eliminate the need for adding
  slack integration to all of our travis configurations)
  - Looks like this may not be possible, at least not securely. Travis can fire
    known integrations (e.g., IRC, Slack), or webhooks. With webhooks, you
    provide a URL **only**, along with a list of notification types to
    enable/disable/etc. The problem here is that there's nothing restricting
    _anyone_ from pushing to that URL, which could result in a denial of
    service.
    We could potentially block any request not originating from travis-ci, or
    not containing expected payload data, or that's from an unexpected repo.
    However, we still run the risk of a DoS.
- [ ] rss integration
  - Do we need it? Twitter gets all of the RSS feeds currently...
- [ ] Do we run webhooks?
  - decide if github and/or travis will operate as webhooks. If not, do not
    expose port 9001, and remove the port configuration from the .env file.
- [x] github integration (see lorna's repo)
  - Right now, I have it polling. We _could_ set this up as a webhook, and use a
    token to do so, since github allows automating setup of webhooks via the
    API. If we do that, we can go with Lorna's repo, though I'd likely go with
    our own formatting.

## Notes

- https://github.com/slackapi/hubot-slack/pull/314#issuecomment-260242790
  detailed how to send "attachments", which gives me better control over 
  visualization of messages.

- We could actually create github pubsubhubbub endpoints (see
  https://developer.github.com/v3/repos/hooks/#pubsubhubbub) within hubot (see
  https://hubot.github.com/docs/scripting/#http-listener for how to expose a
  server). Essentially, we can subscribe to different events, such as:

  - create (reacting when a tag is created)
  - issue_comment
  - issues
  - pull_request_review_comment
  - pull_request_review
  - pull_request
  - release (which might be better than create for detailing a tag)
  - status (build status!)

  Doing this means we could get rid of the github and travis integrations in
  slack, and also remove the slack notifications from the individual repo
  `.travis.yml` files, since we could get the build status information as soon
  as it's received by github. It also means we'd not need to manually add
  integrations to github; we would simply use the github API once for every
  repository to subscribe; we could even build functionality into the bot to
  allow us to subscribe/unsubscribe from within slack itself (obviously, this
  would require ACLs!).

  Finally, there are security things we can do. We can provide a shared secret
  key for generating a SHA1 HMAC of the body content provided in notifications
  when subscribing, allowing us to verify the source of pushes; if the
  X-Hub-Signature header is missing, we can reject it immediately, and if the
  signature does not match the content, we can reject as well.

  Doing this would require putting an SSL proxy in front of hubot, as PuSH
  requires SSL endpoints. This can be done with nginx; see
  http://www.snip2code.com/Snippet/38686/nginx-configuration-file-to-act-as-SSL-p
  for an example. Essentially, I'd add another service to the
  `docker-compose.yml` for nginx that would add that nginx config, and likely
  use letsencrypt to create an SSL cert, and expose port 443 (or, in the case of
  development, 9001) on that service. The hubot service would expose (internally
  only) its own port (likely 8080 in this case), to which nginx would proxy.

  What's more: this can also be done for Discourse, via the webhook plugin, if
  the folks at Discourse will allow it. In that case, our integration becomes
  primarily a pubsubhubbub endpoint that messages slack on notification from its
  sources.
