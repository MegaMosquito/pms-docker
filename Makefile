#
# Official pms-docker image build for arm64, configured for my purposes
#
# Written by Glen Darling (mosquito@darlingevil.com), December 2022.
#

NAME         := pms-docker
DOCKERHUB_ID := ibmosquito
VERSION      := 1.0.0

# Get a fresh claim at: https://www.plex.tv/claim/ (valid only for 4 minutes)
PLEX_CLAIM   :=claim-MGBgZg3iSzT1KMdKPzPK

# Useful bits from https://github.com/MegaMosquito/netstuff/blob/master/Makefile
LOCAL_DEFAULT_ROUTE     := $(shell sh -c "ip route | grep default | sed 's/dhcp src //'")
LOCAL_ROUTER_ADDRESS    := $(word 3, $(LOCAL_DEFAULT_ROUTE))
LOCAL_DEFAULT_INTERFACE := $(word 5, $(LOCAL_DEFAULT_ROUTE))
LOCAL_IP_ADDRESS        := $(word 7, $(LOCAL_DEFAULT_ROUTE))

# My hosts have password access disabled, so they require an ssh key
KEY_FILE :=~/Desktop/Keys/home

# By default, build, push, and run (claim might go stale by the end though)
default: build push

# Build my own copy
build:
	docker build -t $(DOCKERHUB_ID)/$(NAME):$(VERSION) -f Dockerfile.arm64 .

# Run the damned thing
run: stop
	docker run -d --restart unless-stopped \
	  --name $(NAME) \
	  --network=host \
	  -e TZ="America/Los_Angeles" \
	  -e PLEX_CLAIM=$PLEX_CLAIM \
	  -v /home/pi/PLEX/config:/config \
	  -v /home/pi/PLEX/transcode:/transcode \
	  -v /media/pi/UNTITLED/share:/data \
	  $(DOCKERHUB_ID)/$(NAME):$(VERSION)

# Show command to create required tunnel for setup at http://localhost:32400
tunnel:
	@echo "ssh -i $KEY_FILE pi@LOCAL_IP_ADDRESS -L 32400:127.0.0.1:32400 -N

# Push the conatiner to DockerHub (you need to `docker login` first of course)
push:
	docker push $(DOCKERHUB_ID)/$(NAME):$(VERSION)

# Stop the daemon container
stop:
	@docker rm -f ${NAME} >/dev/null 2>&1 || :

# Stop the daemon container, and cleanup
clean: stop
	@docker rmi -f $(DOCKERHUB_ID)/$(NAME):$(VERSION) >/dev/null 2>&1 || :

# Declare all of these non-file-system targets as .PHONY
.PHONY: default build run push stop
