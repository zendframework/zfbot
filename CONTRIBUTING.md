# CONTRIBUTING

Everyone is welcome to contribute to zf-bot. Contributing doesn’t just mean
submitting pull requests; there are many different ways for you to get involved,
including answering questions in chat, reporting or triaging issues, and
documenting the bot.

## Conduct

No matter how you want to get involved, we ask that you first learn what’s
expected of anyone who participates in the project by reading the [Code
Manifesto](CODE_OF_CONDUCT.md). By participating, you are expected to follow its
guidelines and contribute positively within the community.

## Pull Requests

We love pull requests. Here's a quick guide:

- Check for [existing issues](../issues) for duplicates and confirm that it hasn't
  been fixed already in the [master branch](../).
- Fork the repo, and clone it locally.
- Create a new branch for your contribution.
- Add tests if you are able to. Currently, we have no tests, so proposing a
  testing framework and initial tests would be an excellent way to contribute!
- Provide a fix if you are capable.
- Push to your fork and submit a pull request.

At this point you're waiting on us. We may suggest some changes or improvements
or alternatives. Please be aware that this is one of close to 200 repositories
we maintain, so we may not be able to review your issues and pull requests for a
matter of days or weeks.

If you're adding a new feature, it should not conflict with existing features;
conflicts will need to be resolved and/or justified so we may roll out the new
feature.

If you are proposing a change to a user-facing API, we will need a
justification: does it simplify usage? does it provide forwards compatibility
with another proposed feature? does it make usage more flexible, allowing new
features in the future? etc.

Some things that will increase the chance that your pull request is accepted:

- Make sure the tests pass (once we have some!).
- Update the documentation: code comments, example code, guides. Basically,
  update everything affected by your contribution.
- Include any information that would be relevant to reproducing bugs, use cases
  for new features, etc.
- Your commits are associated with your GitHub user: https://help.github.com/articles/why-are-my-commits-linked-to-the-wrong-user/
- Make pull requests against the correct branch. Bugfixes should be submitted
  against master, new features against develop.

### Stale issue and pull request policy

Issues and pull requests have a shelf life and sometimes they are no longer
relevant. All issues and pull requests that have not had any activity for 180
days will be marked as stale. Simply leave a comment with information about why
it may still be relevant to keep it open. If no activity occurs in the next 7
days, we will close it.

The goal of this process is to keep the list of open issues and pull requests
focused on work that is actionable and important for the maintainers and the
community.

## Releases

We use semantic versioning when releasing the bot. Once merged into the master
branch, we will release a new maintenance or _patch_ version of the project,
followed by a new maintentance release of its associated docker repository.

As such:

- _fixes_ will bump the patch version: e.g., 1.2.3 will bump to 1.2.4.
- _features_ that contain no breaking changes will bump the minor version: e.g.,
  1.2.3 will bump to 1.3.0.
- _breaking changes_ will bump the major version: e.g., 1.2.3 would bump to 2.0.0.

## Working with the bot

Since this is a chatbot, you will need to do some functional testing!

### Tokens and integrations

This requires some setup. First, you will need:

- A sandbox Slack to play in. Create one of your own, or ask @weierophinney for
  access to his.
- If you are using your own Slack, you will need to add the Hubot integration to
  your Slack. Make a note of the generated API token, the bot's name, and the
  slack name to which you will connect.
- Twitter consumer key and secret, and access token key and secret. For this,
  you will need to create a Twitter app integration via https://apps.twitter.com.
- A Discourse API key; ask @weierophinney for one when you're ready.
- A GitHub personal access token: https://github.com/settings/tokens

With that information:

- Copy `.env.dist` to `.env`.
- Fill in the details of `.env` based on the information you've gathered and/or
  created.

### Docker

You can use [docker-compose](https://docs.docker.com/compose/) to fire up your
instance. By default:

- The bot itself will be listening on port 9001 for any payloads that are
  expected to come from the web; these might be github webhooks, etc.
- An nginx reverse proxy will listen on port 8080, and forward requests to the
  bot. At the time of writing, any paths not matching `/github/` will be served
  a static page, so you may need to alter the `etc/ngnix/nginx.dev.conf` and/or
  `etc/nginx/nginx.conf` files to allow other paths.
- Redis will be listening on port 6379.

The project contains two `Dockerfile`s:

- `etc/docker/hubot.Dockerfile` details the container for the bot.
- `etc/docker/nginx.Dockerfile` details the nginx reverse proxy configuration
  used in production.

The `docker-compose.yml` file details how the various containers relate in
development, and the `docker-stack.yml` file configures the containers for
production. In most cases, you should not need to make changes to this latter
file.

You can _override_ or _add to_ settings in the `docker-compose.yml` by creating
a `docker-compose.override.yml` file. With recent versions of `docker-compose`,
these are now merged together automatically. We provide a `.gitignore` rule to
ensure the override file is not contributed accidently.
