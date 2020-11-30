// +build integration

package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"testing"
)

func TestSuccessfulHealthcheck(t *testing.T) {
	type result struct {
		code int
		body string
	}

	apiEndpoint, ok := os.LookupEnv("API_ENDPOINT")
	if !ok {
		t.Error("Please define the endpoint for /healthcheck with API_ENDPOINT")
		return
	}
	resp, err := http.Get(fmt.Sprintf("%s/healthcheck", apiEndpoint))
	if err != nil {
		t.Error("Didn't expect an error but got one.)")
		return
	}

	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		t.Errorf("Didn't expect an error while reading the body but got one.")
		return
	}

	want := result{
		code: 200,
		body: "{\"message\":\"hello\"}",
	}
	got := result{
		code: resp.StatusCode,
		body: string(body),
	}
	if want != got {
		t.Errorf("Wanted %+v, got %+v", want, got)
	}
}
