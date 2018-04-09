# Release Process

This document is only for those who have access to the server, and the
production tokens.

## Creating images

- zfbot:
  ```bash
  $ make zfbot
  ```
  Note: requires a `.env` file with all appropriate tokens; see `.env.dist` for
  a template.

- zfbot-nginx:
  ```bash
  $ make nginx
  ```

- zfbot-caddy:
  ```bash
  $ make caddy
  ```
  Note: requires a `.caddy.env` file with definitions for the env vars
  `CADDY_WEB_HOST` and `CADDY_TLS_EMAIL`.

## Deployment

Several things to remember:

- `eval $(docker-machine env zfbot)`
- If never before deployed, run `docker swarm init --advertise-addr $(docker-machine url zfbot | sed 's#tcp://##' | sed -r 's#:[0-9]+$##')`

I had to create networks for each of `public` and `server` (a) to allow the
containers to talk to each other, and (b) to expose a network publicly. I used
`docker network create --driver=overlay --attachable {network-name}` to do this
in each case. This must be done in swarm mode!

The above are all necessary to ensure that the environment is correctly
initialized before deployment. If you've done multiple releases between logins
and within the same shell, you may get messages saying these steps have already
been done; don't take that for granted, though!

Once ready:

```bash
$ make deploy
```

Typically, this will only update containers with updated images, or where
configuration in `docker-stack.yml.dist` has occurred.
