package flightawarebot

import (
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/carlosonunez/flightaware_bot/internal/constants"
	"github.com/carlosonunez/flightaware_bot/internal/constants/classes"
	"github.com/carlosonunez/flightaware_bot/internal/constants/selectors"
	"github.com/carlosonunez/flightaware_bot/internal/logging"
	"github.com/carlosonunez/flightaware_bot/internal/session"

	log "github.com/sirupsen/logrus"
)

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

// GetFlight fetches a flight from flightaware.com and returns it as a Flight.
func GetFlight(flightID string) (Flight, error) {
	// This parses a Flightaware page and returns flight data from it.

	logging.Start()

	faBaseURL := constants.FlightAwareBaseUrl
	if val, ok := os.LookupEnv("FLIGHTAWARE_BASE_URL"); ok {
		faBaseURL = val
	}

	f := session.NewSession(faBaseURL, flightID)
	defer f.Close()
	err := f.Load()
	if err != nil {
		return Flight{}, fmt.Errorf("Failed to render FlightAware page: %s", err)
	}
	data := Flight{
		FlightNumber:    fromPage(classes.FlightIdentifierClass, f),
		Origin:          fromPage(classes.OriginClass, f),
		OriginCity:      fromPage(classes.OriginCityClass, f),
		Destination:     fromPage(classes.DestinationClass, f),
		DestinationCity: fromPage(classes.DestinationCityClass, f),
		DepartureTime:   fromPage(classes.DepartureTimeClass, f),
		EstTakeoffTime:  fromPage(classes.EstTakeoffTimeClass, f),
		EstLandingTime:  fromPage(classes.EstLandingTimeClass, f),
		ArrivalTime:     fromPage(classes.ArrivalTimeClass, f),
	}
	if err != nil {
		return Flight{}, err
	}
	return data, nil
}

func fromPage(className string, f *session.FlightAwareSession) string {
	switch className {
	case classes.FlightIdentifierClass:
		return flightNumber(textFromElementOrPanic(f, className))
	case classes.OriginClass, classes.DestinationClass:
		return airportIATA(textFromElementOrPanic(f, className, selectors.AirportIATA))
	case classes.OriginCityClass, classes.DestinationCityClass:
		return originCity(textFromElementOrPanic(f, className))
	case classes.DepartureTimeClass, classes.ArrivalTimeClass:
		return departOrArriveTime(f, className)
	case classes.EstTakeoffTimeClass, classes.EstLandingTimeClass:
		return takeoffOrLandingTime(f, className)
	default:
		panic(fmt.Sprintf("Unknown class: %s", className))
	}
}

func textFromElementOrPanic(f *session.FlightAwareSession, id string, idx ...int) string {
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

func flightNumber(elem string) string {
	return strings.TrimSpace(strings.Split(elem, "/")[0])
}

func airportIATA(elem string) string {
	data := strings.TrimSpace(elem)
	return strings.Split(data, "\n")[0]
}

func originCity(elem string) string {
	return fixCityString(strings.TrimSpace(elem))
}

func departOrArriveTime(f *session.FlightAwareSession, className string) string {
	dateClass, dateSelector, timeClass, timeSelector := dtClassesAndSelectors(className)
	dateData := strings.TrimSpace(textFromElementOrPanic(f, dateClass, dateSelector))
	timeData := strings.TrimSpace(textFromElementOrPanic(f, timeClass, timeSelector))
	return formattedDateTime(dateData, timeData)
}

func takeoffOrLandingTime(f *session.FlightAwareSession, className string) string {
	const noTimeFound = "--"
	dateClass, dateSelector, timeClass, timeSelector := dtClassesAndSelectors(className)
	dateData := strings.TrimSpace(textFromElementOrPanic(f, dateClass, dateSelector))
	timeData := strings.TrimSpace(textFromElementOrPanic(f, timeClass, timeSelector))
	if timeData == noTimeFound {
		if className == classes.EstTakeoffTimeClass {
			return fromPage(classes.DepartureTimeClass, f)
		}
		return fromPage(classes.ArrivalTimeClass, f)
	}
	return formattedDateTime(dateData, timeData)
}

func formattedDateTime(d string, t string) string {
	// Holy shit. The _numbers_ you use here MUST match what's provided by time.Format.
	// The documentation doesn't make this clear AT ALL.
	// https://golang.org/src/time/format.go
	const exampleInputDateForm = "02-Jan-2006 15:04PM MST"
	dateStr := getDate(d)
	timeStr := getTime(t)
	dt, err := time.Parse(exampleInputDateForm, fmt.Sprintf("%s %s", dateStr, timeStr))
	if err != nil {
		return fmt.Sprintf("Time unavailable: %s", err)
	}
	dtStr := fmt.Sprintf("%d-%02d-%02d %02d:%02d %s",
		dt.Year(),
		dt.Month(),
		dt.Day(),
		dt.Hour(),
		dt.Minute(),
		t[strings.LastIndex(t, " ")+1:])
	log.Debugf("Returning %s from date %s and time %s", dtStr, d, t)
	return dtStr
}

func dtClassesAndSelectors(className string) (string, int, string, int) {
	var dateClass string
	var timeSelector int
	var dateSelector int
	timeClass := classes.TimeClass
	switch className {
	case classes.DepartureTimeClass:
		dateClass = classes.OriginClass
		dateSelector = selectors.OriginFlightDate
		timeSelector = selectors.EstOriginDepartureTime
	case classes.EstTakeoffTimeClass:
		dateClass = classes.OriginClass
		dateSelector = selectors.OriginFlightDate
		timeSelector = selectors.EstOriginTakeoffTime
	case classes.EstLandingTimeClass:
		dateClass = classes.DestinationClass
		dateSelector = selectors.DestinationFlightDate
		timeSelector = selectors.EstDestinationLandingTime
	case classes.ArrivalTimeClass:
		dateClass = classes.DestinationClass
		dateSelector = selectors.DestinationFlightDate
		timeSelector = selectors.EstDestinationArrivalTime
	default:
		panic(fmt.Sprintf("Invalid class: %s", className))
	}
	log.Debugf("dateClass: %s, dateSelector: %d, timeClass: %s, timeSelector: %d",
		dateClass,
		dateSelector,
		timeClass,
		timeSelector)
	return dateClass, dateSelector, timeClass, timeSelector
}

func getDate(s string) string {
	log.Debugf("Splitting by newline and space, getting 0th and 1st: %s", s)
	return strings.Split(strings.Split(s, "\n")[0], " ")[1]
}

func getTime(s string) string {
	log.Debugf("Splitting time by newline, getting 1st: %s", s)
	return strings.Split(s, "\n")[0]
}

func fixCityString(s string) string {
	log.Debugf("Formatting city string %s", s)
	parts := strings.Split(s, ",")
	city := strings.ToLower(parts[0])
	return fmt.Sprintf("%s,%s", strings.Title(city), strings.Join(parts[1:], ""))
}
