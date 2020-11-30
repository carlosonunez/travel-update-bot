MAKEFLAGS += --silent
SHELL := /usr/bin/env bash
DOCKER_COMPOSE := $(shell which docker-compose)
DOCKER_COMPOSE_DEPLOY := $(shell which docker-compose) -f docker-compose.deploy.yml
VENDOR ?= false ## Do you want to vendor dependencies before running test tests?
LOG_LEVEL ?= info ## Changes log verbosity. Supported: info, debug
.DEFAULT_GOAL := build

export LOG_LEVEL
export DISABLE_TEARDOWN
export VENDOR

.PHONY: clean vendor unit local_e2e usage build integration deploy_integration destroy_integration integration_test

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

vendor_firefox: ## Copies the firefox Lambda layer locally. Remove firefox.zip to re-run.
	if ! test -f layers/firefox.zip; \
	then \
		mkdir -p layers && \
			url=$$(grep -r "ENV FIREFOX_LAMBDA_URL" app.Dockerfile | cut -f2 -d =); \
			curl -Lo layers/firefox.zip $$url; \
	fi


build: vendor
build:
	find ./*.go -maxdepth 1 | \
		grep -v _test | \
		while read file; \
		do \
			name=$$(basename $$file | sed 's/.go$$//'); \
			$(DOCKER_COMPOSE) run --rm build -o bin/$$name $$file; \
		done

unit: vendor
unit: ## Runs unit tests.
	$(DOCKER_COMPOSE) run --rm unit ./...

integration: deploy_integration integration_test destroy_integration ## Runs integration tests with setup and teardown.

integration_test: ## Runs integration tests by themselves. Tests should be at the top-level of this repo.
	endpoint=$$($(DOCKER_COMPOSE_DEPLOY) run --rm serverless info --stage develop | \
					 grep -r "GET -" | \
					 sed 's/.*GET - //' | \
					 sed 's/\(\/develop\).*/\1/'); \
	API_ENDPOINT=$$endpoint $(DOCKER_COMPOSE) run --rm integration .


local_e2e: vendor
local_e2e: ## Runs local end-to-end tests against a local webserver.
	$(DOCKER_COMPOSE) up -d local-flightaware && \
		$(DOCKER_COMPOSE) run --rm local_e2e ./...

deploy_integration: vendor vendor_firefox build
deploy_integration: ## Deploys the FlightAware serverless functions into an integration env.
	for stage in deploy-serverless-infra-test deploy-serverless-functions-test; \
	do $(DOCKER_COMPOSE_DEPLOY) -f run --rm "$$stage" || exit 1; \
	done

destroy_integration: ## Destroys the serverless integration environment.
	$(DOCKER_COMPOSE_DEPLOY) run --rm serverless remove --stage develop && \
	$(DOCKER_COMPOSE_DEPLOY) run --rm destroy-serverless-infra-test
