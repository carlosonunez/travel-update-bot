#!/usr/bin/env bash
AWS_CREDS_TEMP_FP="$(mktemp ${TMPDIR:-/tmp}/aws-session-credentials-"$(date +%s)"-XXXXX)"
generate_aws_credentials() {
  info "Pulling AWS image to avoid next command mangling image pull info"
  docker-compose -f docker-compose.deploy.yml pull obtain-aws-session-credentials
  info "Retrieving an AWS session token"
  printf "AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s AWS_SESSION_TOKEN=%s" \
    $(docker-compose -f docker-compose.deploy.yml run -T --rm obtain-aws-session-credentials) \
    >> "$AWS_CREDS_TEMP_FP"
}

remove_aws_credentials() {
  info "Removing AWS credentials"
  rm -f "$AWS_CREDS_TEMP_FP"
}

get_aws_credentials() {
  cat "$AWS_CREDS_TEMP_FP"
}
