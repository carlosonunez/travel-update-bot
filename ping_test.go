package flightaware_bot

import "testing"

func TestPingSuccessful(t *testing.T) {
	expected := "hello"
	got, err := flightaware_bot.ping()
	if err != nil {
		t.Error(err)
	}
	if got != expected {
		t.Error("Expected %s, but got %s", expected, hello)
	}
}
