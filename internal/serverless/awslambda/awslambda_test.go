// +build unit

package awslambda_test

import (
	"testing"

	"github.com/carlosonunez/flightaware_bot/internal/serverless/awslambda"
)

func TestHttpOkNoBody(t *testing.T) {
	want := "{\"statusCode\":200,\"body\":{}}"
	got := awslambda.Ok()
	if want != got {
		t.Errorf("Expected %s but got %s", want, got)
	}
}

func TestHttpOkBody(t *testing.T) {
	type body struct {
		Foo string `json:"foo"`
	}
	want := "{\"statusCode\":200,\"body\":{\"foo\":\"bar\"}}"
	got := awslambda.Ok(&body{Foo: "bar"})
	if want != got {
		t.Errorf("Expected %s but got %s", want, got)
	}
}

// TestHttpError returns a HTTP 422 because Lambda eats HTTP 400s.
func TestHttpError(t *testing.T) {
	want := "{\"statusCode\":422,\"body\":{\"error\":\"Test message.\"}}"
	got := awslambda.Error("Test message.")
	if want != got {
		t.Errorf("Expected %s but got %s", want, got)
	}
}
