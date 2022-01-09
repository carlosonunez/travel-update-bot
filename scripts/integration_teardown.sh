#!/usr/bin/env bash

stop_integration_test_services() {
  while read -r svc
  do
    docker-compose stop "$svc"
  done < <(grep -E 'integration-test.*:' docker-compose.yml | sed 's/^ +//' | tr -d ':')
}

stop_integration_test_services || true
