# zfbot.mwop.net Makefile
#
# Create a docker-stack.yml based on latest tags of required containers, and
# deploy to swarm.
#
# Allowed/expected variables:
#
# - CADDY_VERSION: specific caddy container version to use
# - NGINX_VERSION: specific nginx container version to use
# - ZFBOT_VERSION: specific zfbot container version to use
#
# If not specified, each defaults to "latest", which forces a lookup of the
# latest tagged version.

VERSION := $(shell date +%Y%m%d%H%M)

CADDY_VERSION?=latest
NGINX_VERSION?=latest
ZFBOT_VERSION?=latest

.PHONY : all deploy caddy nginx zfbot

all: check-env deploy caddy nginx zfbot

check-env:
ifndef DOCKER_MACHINE_NAME
	$(error DOCKER_MACHINE_NAME is undefined; run "eval $$(docker-machine env zfbot)" first)
endif
ifneq ($(DOCKER_MACHINE_NAME),zfbot)
	$(error DOCKER_MACHINE_NAME is incorrect; run "eval $$(docker-machine env zfbot)" first)
endif

docker-stack.yml:
	@echo "Creating docker-stack.yml"
	@echo "- caddy container version: $(CADDY_VERSION)"
	@echo "- nginx container version: $(NGINX_VERSION)"
	@echo "- zfbot container version: $(ZFBOT_VERSION)"
	- $(CURDIR)/bin/create-docker-stack.php -n $(NGINX_VERSION) -b $(ZFBOT_VERSION) -c ${CADDY_VERSION}

deploy: check-env docker-stack.yml
	@echo "Deploying to swarm"
	- docker stack deploy --with-registry-auth -c docker-stack.yml zfbot
	- rm docker-stack.yml

nginx:
	@echo "Creating nginx container"
	@echo "- Building container"
	- docker build -t zfbot-nginx -f ./etc/docker/nginx.Dockerfile .
	@echo "- Tagging image"
	- docker tag zfbot-nginx:latest mwop/zfbot-nginx:$(VERSION)
	@echo "- Pushing image to hub"
	- docker push mwop/zfbot-nginx:$(VERSION)

caddy:
	@echo "Creating caddy container"
	@echo "- Building container"
	- docker build -t zfbot-caddy -f ./etc/docker/caddy.Dockerfile .
	@echo "- Tagging image"
	- docker tag zfbot-caddy:latest mwop/zfbot-caddy:$(VERSION)
	@echo "- Pushing image to hub"
	- docker push mwop/zfbot-caddy:$(VERSION)

zfbot:
	@echo "Creating zfbot container"
	@echo "- Building container"
	- docker build -t zfbot -f ./etc/docker/hubot.Dockerfile .
	@echo "- Tagging image"
	- docker tag zfbot:latest mwop/zfbot:$(VERSION)
	@echo "- Pushing image to hub"
	- docker push mwop/zfbot:$(VERSION)
