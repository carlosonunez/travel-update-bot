MAKEFLAGS += --silent
SHELL := /usr/bin/env bash
DOCKER_COMPOSE := $(shell which docker-compose)
VENDOR ?= false ## Do you want to vendor dependencies before running unit tests?
DISABLE_TEARDOWN ?= false ## Do you want to keep Selenium Hub running?
LOG_LEVEL ?= info ## Changes log verbosity. Supported: info, debug

export LOG_LEVEL
export DISABLE_TEARDOWN
export VENDOR

.PHONY: clean vendor unit usage

usage: ## Prints this help text.
	printf "make [target]\n\
Hack on flightaware-bot.\n\
\n\
TARGETS\n\
\n\
$$(fgrep -h '##' $(MAKEFILE_LIST) | fgrep -v '?=' | fgrep -v grep | sed 's/\\$$//' | sed -e 's/##//' | sed 's/^/  /g')\n\
\n\
ENVIRONMENT VARIABLES\n\
\n\
$$(fgrep '?=' $(MAKEFILE_LIST) | grep -v grep | sed 's/\?=.*##//' | sed 's/^/  /g')\n\
\n\
NOTES\n\
\n\
	- Add VENDOR=true behind make to vendor Go modules before running your tests.\n\
	- Adding a new stage? Add a comment with two pound signs after the stage name to add it to this help text.\n"

clean: ## Remove vendored packages and other temporary files.
	$(DOCKER_COMPOSE) down && rm -r vendor

# TECH NOTE: Why are we rebuilding our Docker Compose images instead of using
# volume mounts?
#
# This was developed on a Mac. Docker for Mac has notoriously bad IO performance
# with volume mounts with the added bonus of cutting my MacBook's battery life in half.
# While building the Docker image adds some latency to our tests, it speeds up
# tests overall and preserves energy.
vendor: ## Vendors your dependencies.
	if test "$(VENDOR)" == "true"; \
	then \
		$(DOCKER_COMPOSE) build vendor && $(DOCKER_COMPOSE) run --rm vendor; \
	fi

unit: vendor
unit: ## Runs unit tests.
	$(DOCKER_COMPOSE) build unit && \
		$(DOCKER_COMPOSE) up --build -d selenium && \
		$(DOCKER_COMPOSE) exec selenium sh -c "pkill chrome"; \
		$(DOCKER_COMPOSE) run --rm unit; \
		if test "$(DISABLE_TEARDOWN)" != "true"; \
		then \
			$(DOCKER_COMPOSE) down; \
		fi
