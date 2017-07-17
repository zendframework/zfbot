# Changelog

All notable changes to this project will be documented in this file, in reverse chronological order by release.

## 0.3.4 - 2017-07-17

### Added

- Nothing.

### Deprecated

- Nothing.

### Removed

- Nothing.

### Fixed

- Fixes error handling when unable to parse JSON returned when fetching topics
  from Discourse.

## 0.3.3 - 2017-07-17

### Added

- Adds logging of rejected releases from the GitHub release callback handler.

### Deprecated

- Nothing.

### Removed

- Nothing.

### Fixed

- Nothing.

## 0.3.2 - 2017-07-17

### Added

- Nothing.

### Deprecated

- Nothing.

### Removed

- Nothing.

### Fixed

- Fixes a typo when importing the crypto library within the github-release
  handler.

## 0.3.1 - 2017-07-17

### Added

- Adds the ability to notify a configured callback URL with GitHub release
  details once processing of the release is complete.

### Deprecated

- Nothing.

### Removed

- Nothing.

### Fixed

- Nothing.

## 0.3.0 - 2017-07-11

### Added

- Adds the following commands (both behind authorization):
  - `zfbot tweet <message>`
  - `zfbot retweet <id or URI>`

### Deprecated

- Nothing.

### Removed

- Nothing.

### Fixed

- Nothing.

## 0.2.2 - 2017-07-11

### Added

- Nothing.

### Deprecated

- Nothing.

### Removed

- Nothing.

### Fixed

- Fixes an issue with the catch-all when a message contains no text.

## 0.2.1 - 2017-07-10

### Added

- Nothing.

### Deprecated

- Nothing.

### Removed

- Nothing.

### Fixed

- Catches `JSON.parse` errors in the Discourse plugin.

## 0.2.0 - 2017-07-06

### Added

- The `tweetstream` plugin now exposes a `tweet` event on the robot instance,
  allowing other plugins to send tweets.
- The github-release integration now sends a tweet via the `tweet` event.

### Deprecated

- Nothing.

### Removed

- Nothing.

### Fixed

- Nothing.

## 0.1.0 - 2017-07-05

Initial (stable?) release of zfbot.

### Added

- ACL system; only people in the ACL whitelist can perform privileged actions.
- Twitter: follow users or track searches, per room.
- Discourse: follow Discourse categories for the configured Discourse instance, per room.
- GitHub: subscribe via PubSubHubbub to GitHub events for a given repository, per room. Currently knows about:
  - issue creation and closure.
  - issue comments.
  - pull request creation, merging, and closure.
  - pull request comments (these are issue comments).
  - pull request reviews and comments.
  - releases.
  - status updates (for success, failure, and error states).

### Deprecated

- Nothing.

### Removed

- Nothing.

### Fixed

- Nothing.
