package main

import (
	"context"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/carlosonunez/flightaware_bot/internal/functions/ping"
	"github.com/carlosonunez/flightaware_bot/internal/serverless/awslambda"
)

type request struct{}

func healthcheck(_ context.Context, _ request) string {
	return awslambda.Ok(ping.Ping())
}

func main() {
	lambda.Start(healthcheck)
}
