package flightawarebot

import (
	"os"
	"testing"

	"github.com/carlosonunez/flightaware_bot/test/mocks"
	"github.com/google/go-cmp/cmp"
)

func TestSuccessWhenFlightNumberKnown(t *testing.T) {
	if _, present := os.LookupEnv("SELENIUM_HUB_URL"); !present {
		t.Error("Please define SELENIUM_HUB_URL in your environment.")
		t.FailNow()
	}
	tests := map[string]Flight{
		"KnownTakeoffAndLanding": Flight{
			FlightNumber:    "AAL1",
			Origin:          "JFK",
			OriginCity:      "New York, NY",
			Destination:     "LAX",
			DestinationCity: "Los Angeles, CA",
			DepartureTime:   "2019-10-27 07:53 EDT",
			EstTakeoffTime:  "2019-10-27 08:17 EDT",
			EstLandingTime:  "2019-10-27 11:11 PDT",
			ArrivalTime:     "2019-10-27 11:18 PDT",
		},
		"UnknownTakeoffAndLanding": Flight{
			FlightNumber:    "AAL356",
			Origin:          "OMA",
			OriginCity:      "Omaha, NE",
			Destination:     "DFW",
			DestinationCity: "Dallas-Fort Worth, TX",
			DepartureTime:   "2019-11-07 20:23 CST",
			EstTakeoffTime:  "2019-11-07 20:23 CST",
			EstLandingTime:  "2019-11-07 22:20 CST",
			ArrivalTime:     "2019-11-07 22:20 CST",
		},
	}
	session := &mocks.MockFlightAwareSession{}
	for name, want := range tests {
		t.Run(name, func(t *testing.T) {
			got, err := getFlight(session, want.FlightNumber)
			if err != nil {
				t.Errorf("Wasn't expecting an error, but got one: %s", err)
				t.FailNow()
			}
			if !cmp.Equal(want, got) {
				t.Errorf("Expected: %+v\nGot: %+v", want, got)
			}
		})
	}
}
