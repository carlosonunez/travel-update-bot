#!/usr/bin/env bash

stop_integration_test_services() {
  docker-compose down
}

stop_integration_test_services || true
