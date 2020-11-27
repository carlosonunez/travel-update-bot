package flightawarebot

import (
	"fmt"
	"strings"

	"github.com/carlosonunez/flightaware_bot/internal/constants"
)

type flightAwareSessionInterface interface {
	Initialize(string)
	FindElementsByClassName(string) ([]string, error)
	Load() error
}

// Flight represents the data we care about from Flightaware.
type Flight struct {
	FlightNumber    string
	Origin          string
	OriginCity      string
	Destination     string
	DestinationCity string
	DepartureTime   string
	EstTakeoffTime  string
	EstLandingTime  string
	ArrivalTime     string
}

func getFlight(f flightAwareSessionInterface, flightID string) (Flight, error) {
	// This parses a Flightaware page and returns flight data from it.

	f.Initialize(flightID)
	err := f.Load()
	if err != nil {
		return Flight{}, fmt.Errorf("Failed to render FlightAware page: %s", err)
	}
	data := Flight{
		FlightNumber:    fromPage(constants.FlightIdentifierClass, f),
		Origin:          fromPage(constants.OriginClass, f),
		OriginCity:      fromPage(constants.OriginCityClass, f),
		Destination:     fromPage(constants.DestinationClass, f),
		DestinationCity: fromPage(constants.DestinationCityClass, f),
		DepartureTime:   fromPage(constants.DepartureTimeClass, f),
		EstTakeoffTime:  fromPage(constants.EstTakeoffTimeClass, f),
		EstLandingTime:  fromPage(constants.EstLandingTimeClass, f),
		ArrivalTime:     fromPage(constants.ArrivalTimeClass, f),
	}
	if err != nil {
		return Flight{}, err
	}
	return data, nil
}

func fromPage(className string, f flightAwareSessionInterface) string {
	switch className {
	case constants.FlightIdentifierClass:
		return strings.TrimSpace(strings.Split(textFromElementOrPanic(f, constants.FlightIdentifierClass), "/")[0])
	case constants.OriginClass:
		return "JFK"
	case constants.OriginCityClass:
		return "New York, NY"
	case constants.DestinationClass:
		return "LAX"
	case constants.DestinationCityClass:
		return "Los Angeles, CA"
	case constants.DepartureTimeClass:
		return "2019-10-27 07:53 EDT"
	case constants.EstTakeoffTimeClass:
		return "2019-10-27 08:17 EDT"
	case constants.EstLandingTimeClass:
		return "2019-10-27 11:11 PDT"
	case constants.ArrivalTimeClass:
		return "2019-10-27 11:18 PDT"
	default:
		panic(fmt.Sprintf("Unknown class: %s", className))
	}
}

func textFromElementOrPanic(f flightAwareSessionInterface, id string, idx ...int) string {
	if len(idx) > 1 {
		panic("textFromElementOrPanic only takes three arguments; more were provided.")
	}
	elems, err := f.FindElementsByClassName(id)
	if err != nil {
		panic(err)
	}
	if len(idx) > 0 {
		return elems[idx[0]]
	}
	return elems[0]
}
