#!/usr/bin/env sh
if test -z "$AWS_LAMBDA_RUNTIME_API"
then
  exec /usr/local/bin/aws_lambda_rie aws_lambda_ric "$@"
else
  aws_lambda_ric "$@"
fi
