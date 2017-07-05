# Release Process

This document is only for those who have access to the server, and the
production tokens.

## Creating images

- zfbot:
  ```bash
  $ docker build -t zfbot -f ./etc/docker/hubot.Dockerfile .
  $ docker tag zfbot:latest mwop/zfbot:<tag_version>
  $ docker push mwop/zfbot:<tag_version>
  ```

- zfbot-nginx:
  ```bash
  $ docker build -t zfbot-nginx -f ./etc/docker/nginx.Dockerfile .
  $ docker tag zfbot-nginx:latest mwop/zfbot-nginx:<tag_version>
  $ docker push mwop/zfbot-nginx:<tag_version>
  ```

Once done, update the `docker-stack.yml` to reflect the new tag versions.

## Deployment

Several things to remember:

- Login to Docker Hub: `docker login -u <username>`
- `eval $(docker-machine env zfbot)`
- `docker swarm init --advertise-addr $(docker-machine url zfbot | sed 's#tcp://##' | sed -r 's#:[0-9]+$##')`

The above are all necessary to ensure that the environment is correctly
initialized before deployment. If you've done multiple releases between logins
and within the same shell, you may get messages saying these steps have already
been done; don't take that for granted, though!

Once ready:

```bash
$ docker stack deploy --with-registry-auth -f docker-stack.yml zfbot
```

Typically, this will only update containers with updated images, or where
configuration in `docker-stack.yml` has occurred.

## SSL certs

For this, I use [acme.sh](https://github.com/Neilpang/acme.sh), and used the
following:

```bash
$ export FREEDNS_User="<username on freedns.afraid.org>"
$ export FREEDNS_Password="<password on freedns.afraid.org>"
$ acme.sh --isue --dns dns_freedns -d zfbot.mwop.net
```

This generated the certificates for me, which I then copied into
`etc/nginx/certs/` (ignored by git!) from `$HOME/.acme.sh/zfbot.mwop.net/`.
`acme.sh` has a daily cronjob that will renew them automatically; I'm unsure if
I'll need to update the certs used by nginx, however.
