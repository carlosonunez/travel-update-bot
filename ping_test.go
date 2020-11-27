package flightawarebot

import "testing"

func TestPingSuccessful(t *testing.T) {
	expected := "hello"
	got, err := Ping()
	if err != nil {
		t.Error(err)
	}
	if got != expected {
		t.Errorf("Expected %s, but got %s", expected, got)
	}
}
