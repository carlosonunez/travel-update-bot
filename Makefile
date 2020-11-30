MAKEFLAGS += --silent
SHELL := /usr/bin/env bash
DOCKER_COMPOSE := $(shell which docker-compose)
VENDOR ?= false ## Do you want to vendor dependencies before running test tests?
LOG_LEVEL ?= info ## Changes log verbosity. Supported: info, debug
.DEFAULT_GOAL := build

export LOG_LEVEL
export DISABLE_TEARDOWN
export VENDOR

.PHONY: clean vendor unit local_e2e usage build integration deploy_integration

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

vendor: ## Vendors your dependencies.
	if test "$(VENDOR)" == "true"; \
	then \
		$(DOCKER_COMPOSE) build vendor && $(DOCKER_COMPOSE) run --rm vendor; \
	fi

build: vendor
build:
	find ./*.go -maxdepth 1 | \
		while read file; \
		do \
			name=$$(basename $$file | sed 's/.go$$//'); \
			$(DOCKER_COMPOSE) run --rm build -o bin/$$name $$file; \
		done

unit: vendor
unit: ## Runs unit tests.
	$(DOCKER_COMPOSE) run --rm unit ./...

integration: deploy_integration
integration:
	$(DOCKER_COMPOSE) run --rm integration ./...
integration: destroy_integration


local_e2e: vendor
local_e2e: ## Runs local end-to-end tests against a local webserver.
	$(DOCKER_COMPOSE) up -d local-flightaware && \
		$(DOCKER_COMPOSE) run --rm local_e2e ./...

deploy_integration: vendor build
deploy_integration:
	for stage in deploy-serverless-infra-test deploy-serverless-functions-test; \
	do $(DOCKER_COMPOSE) -f docker-compose.deploy.yml run --rm "$$stage" || exit 1; \
	done

destroy_integration:
	$(DOCKER_COMPOSE) -f docker-compose.deploy.yml run --rm serverless remove --stage develop
