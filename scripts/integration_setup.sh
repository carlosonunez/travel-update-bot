#!/usr/bin/env bash
CHROMIUM_LAYER_VERSION="${CHROMIUM_LAYER_VERSION:-10.1}"
CHROMIUM_LAYER_URI=https://github.com/alixaxel/chrome-aws-lambda/raw/v${CHROMIUM_LAYER_VERSION}/bin/chromium.br
source $(dirname "$0")/helpers/shared_secrets.sh
set -e

get_api_gateway_endpoint() {
  >&2 echo "INFO: Getting integration test API Gateway endpoint."
  remove_secret 'endpoint_name'

  endpoint_url=$(serverless info --stage develop | \
    grep -E 'http.*\/ping' | \
    sed 's/.*\(http.*\)\/ping/\1/' | \
    tr -d $'\r')

  >&2 echo "INFO: Getting API Gateway default API key."
  api_key=$(serverless info --stage develop | \
    grep -E 'default_key:' | \
    sed 's/.*default_key: //' | \
    tr -d ' '
  )
  if test -z "$endpoint_url"
  then
    >&2 echo "ERROR: We couldn't find a deployed endpoint."
    exit 1
  fi
  if test -z "$api_key"
  then
    >&2 echo "ERROR: We couldn't find an API key."
    exit 1
  fi
  export API_GATEWAY_URL="$endpoint_url"
  export API_KEY="$api_key"
  write_secret "$endpoint_url" "endpoint_name"
  write_secret "$api_key" "api_key"
}

fetch_chromium_lambda_layer() {
  chromium_include_fp="$(dirname "$0"/../include/chromium.br)"
  if ! test -f "$chromium_include_fp"
  then
    curl -Lo "$chromium_include_fp" "$CHROMIUM_LAYER_URI"
  fi
}

get_api_gateway_endpoint && fetch_chromium_lambda_layer
