// +build unit

package ping_test

import (
	"testing"

	"github.com/carlosonunez/flightaware_bot/internal/functions/ping"
)

func TestPingSuccessful(t *testing.T) {
	expected := "hello"
	got, err := ping.Ping()
	if err != nil {
		t.Error(err)
	}
	if got != expected {
		t.Errorf("Expected %s, but got %s", expected, got)
	}
}
