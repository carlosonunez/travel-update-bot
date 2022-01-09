#!/usr/bin/env bash
source $(dirname "$0")/helpers/shared_secrets.sh
set -e
DISABLE_API_GATEWAY_FETCH="${DISABLE_API_GATEWAY_FETCH:-false}"

get_api_gateway_endpoint() {
  grep -Eiq '^true$' <<< "$DISABLE_API_GATEWAY_FETCH" && return

  >&2 echo "INFO: Getting integration test API Gateway endpoint."
  remove_secret 'endpoint_name'

  endpoint_url=$(docker-compose -f docker-compose.deploy.yml run --rm serverless info --stage develop | \
    grep -E 'http.*\/ping' | \
    sed 's/.*\(http.*\)\/ping/\1/' | \
    tr -d $'\r')

  >&2 echo "INFO: Getting API Gateway default API key."
  api_key=$(docker-compose -f docker-compose.deploy.yml run --rm serverless info --stage develop | \
    grep -E 'default_key:' | \
    sed 's/.*default_key: //' | \
    tr -d ' '
  )
  if test -z "$endpoint_url"
  then
    >&2 echo "ERROR: We couldn't find a deployed endpoint."
    return 1
  fi
  if test -z "$api_key"
  then
    >&2 echo "ERROR: We couldn't find an API key."
    return 1
  fi
  export API_GATEWAY_URL="$endpoint_url"
  export API_KEY="$api_key"
  write_secret "$endpoint_url" "endpoint_name"
  write_secret "$api_key" "api_key"
}

start_integration_test_services() {
  while read -r svc
  do
    docker-compose up -d "$svc"
  done < <(grep -E 'integration-test.*:' docker-compose.yml | sed 's/^ +//' | tr -d ':')
}

get_api_gateway_endpoint || true
start_integration_test_services || true
