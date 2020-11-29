// +build local_e2e

package flightawarebot_test

import (
	"testing"

	flightawarebot "github.com/carlosonunez/flightaware_bot"
	"github.com/google/go-cmp/cmp"
)

func TestSuccessWhenFlightNumberKnown(t *testing.T) {
	tests := map[string]flightawarebot.Flight{
		"KnownTakeoffAndLanding": flightawarebot.Flight{
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
		"UnknownTakeoffAndLanding": flightawarebot.Flight{
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
	for name, want := range tests {
		t.Run(name, func(t *testing.T) {
			got, err := flightawarebot.GetFlight(want.FlightNumber)
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
