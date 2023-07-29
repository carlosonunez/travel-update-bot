#!/usr/bin/env bash
TAILSCALE_HOSTNAME="${TAILSCALE_HOSTNAME:-lambda-app}"
verify_proxy_host_port_defined() {
  for var in PROXY_HOST PROXY_PORT \
    TAILSCALE_AUTH_KEY TAILSCALE_EXIT_NODE_IP \
    TS_TEST_URL TS_TEST_WANT
  do
    test -n "${!var}" && continue
    >&2 echo "Bootstrap env var not defined: $var"
    return 1
  done

  return 0
}

connect_to_tailscale() {
  proxy_server="${PROXY_HOST}:${PROXY_PORT}"
  mkdir -p /tmp/tailscale
  /var/runtime/tailscaled --tun=userspace-networking \
    --socks5-server="$proxy_server" &
  /var/runtime/tailscale up \
    --authkey="$TAILSCALE_AUTH_KEY" \
    --hostname="$TAILSCALE_HOSTNAME" \
    --exit-node="$TAILSCALE_EXIT_NODE_IP" \
    --accept-routes
}

verify_tailscale_connected() {
  sleep 3
  code=$(curl --socks5-hostname "${PROXY_HOST}:${PROXY_PORT}" \
    -w '%{http_code}' \
    "$TS_TEST_URL")
  test "$code" == "$TS_TEST_WANT"
  res=$?
  >&2 echo "INFO: Test that internal URL $TS_TEST_URL returns $TS_TEST_WANT: $code -> $res"
  return "$res"
}

running_unit_tests() {
  test -z "$RUNNING_UNIT_TESTS"
}

if running_unit_tests
then
  aws_lambda_ric "$@"
  exit $?
fi


verify_proxy_host_port_defined || exit 1
connect_to_tailscale || exit 1
verify_tailscale_connected || exit 1

>&2 echo "INFO: Connected to Tailscale."

export TAILSCALE_PROXY="socks5://${PROXY_HOST}:${PROXY_PORT}"
if test -z "$AWS_LAMBDA_RUNTIME_API"
then
  exec /usr/local/bin/aws_lambda_rie aws_lambda_ric "$@"
else
  aws_lambda_ric "$@"
fi
