SHELL := /usr/bin/env bash
MAKEFLAGS += --silent
DOCKER_COMPOSE := $(shell which docker-compose)

.PHONY: clean vendor unit

clean:
	rm -r vendor

# TECH NOTE: Why are we rebuilding our Docker Compose images instead of using
# volume mounts?
#
# This was developed on a Mac. Docker for Mac has notoriously bad IO performance
# with volume mounts with the added bonus of cutting my MacBook's battery life in half.
# While building the Docker image adds some latency to our tests, it speeds up
# tests overall and preserves energy.
vendor:
	if test "$(VENDOR)" == "true"; \
	then \
		$(DOCKER_COMPOSE) build vendor && $(DOCKER_COMPOSE) run --rm vendor; \
	fi

unit:
	$(DOCKER_COMPOSE) build unit && $(DOCKER_COMPOSE) run --rm unit
