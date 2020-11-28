package flightawarebot

import (
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/carlosonunez/flightaware_bot/internal/constants"
	"github.com/carlosonunez/flightaware_bot/internal/helpers"
	"github.com/carlosonunez/flightaware_bot/internal/logging"
	"github.com/google/go-cmp/cmp"
	log "github.com/sirupsen/logrus"
	"github.com/tebeka/selenium"
)

type TestFlightAwareSessionInterface interface {
	Initialize(string)
	Load() error
}

type TestFlightAwareSession struct {
	remote          selenium.WebDriver
	flightAwarePage string
}

func fixturesPath() string {
	bp, found := os.LookupEnv("FIXTURES_PATH")
	if !found {
		wd, err := os.Getwd()
		if err != nil {
			panic(err)
		}
		return fmt.Sprintf("%s/test/fixtures", wd)
	}
	return bp
}

func (f *TestFlightAwareSession) Initialize(flightNumber string) {
	logging.Start()
	f.flightAwarePage = fmt.Sprintf("file:///%s/test_flight_%s.html",
		fixturesPath(),
		flightNumber)
	capabilities := selenium.Capabilities{"browserName": "chrome"}
	remote, err := selenium.NewRemote(capabilities, os.Getenv("SELENIUM_HUB_URL"))
	if err != nil {
		panic(err)
	}
	f.remote = remote
}

func (f *TestFlightAwareSession) Load() error {
	log.Debugf("About to load: %s", f.flightAwarePage)
	if err := f.remote.Get(f.flightAwarePage); err != nil {
		return err
	}
	return f.waitForPageToFinishLoading()
}

func (f *TestFlightAwareSession) waitForPageToFinishLoading() error {
	foundElements := make(chan bool, 1)
	defer close(foundElements)

	go func() {
		for {
			elems, _ := f.remote.FindElements(selenium.ByXPATH, "//*[@class='flightPageHeading']")
			if len(elems) > 0 {
				log.Debug("FlightAware has loaded.")
				foundElements <- true
				return
			}
			log.Debug("FlightAware hasn't loaded yet.")
			time.Sleep(1 * time.Second)
		}
	}()

	select {
	case <-foundElements:
		return nil
	case <-time.After(constants.FlightAwarePageTimeoutSeconds * time.Second):
		return errors.New("Timed out while waiting for FlightAware to finish loading")
	}
}
func (f *TestFlightAwareSession) FindElementsByClassName(id string) ([]string, error) {
	elems, err := f.remote.FindElements(selenium.ByXPATH, fmt.Sprintf("//*[@class='%s']", id))
	if err != nil {
		return nil, err
	}
	texts := make([]string, len(elems))
	for i, x := range elems {
		texts[i] = helpers.StringMust(x.Text())
	}
	log.Debugf("Sought %s, got %+v", id, texts)
	return texts, nil
}

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
	session := &TestFlightAwareSession{}
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
