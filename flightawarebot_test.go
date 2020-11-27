package flightawarebot

import (
	"fmt"
	"os"
	"strings"
	"testing"

	"github.com/carlosonunez/flightaware_bot/internal/helpers"
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
	log.SetOutput(os.Stdout)
	log.SetReportCaller(true)
	if level, ok := os.LookupEnv("LOG_LEVEL"); ok {
		if strings.ToLower(level) == "debug" || strings.ToLower(level) == "trace" {
			log.SetLevel(log.DebugLevel)
			selenium.SetDebug(true)
		}
	}
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
	err := f.remote.Get(f.flightAwarePage)
	if err != nil {
		return err
	}
	if err != nil {
		panic(err)
	}
	return nil
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

func TestSuccessWhenFlightNumberProvided(t *testing.T) {
	if _, present := os.LookupEnv("SELENIUM_HUB_URL"); !present {
		t.Error("Please define SELENIUM_HUB_URL in your environment.")
		t.FailNow()
	}
	session := &TestFlightAwareSession{}
	want := Flight{
		FlightNumber:    "AAL1",
		Origin:          "JFK",
		OriginCity:      "New York, NY",
		Destination:     "LAX",
		DestinationCity: "Los Angeles, CA",
		DepartureTime:   "2019-10-27 07:53 EDT",
		EstTakeoffTime:  "2019-10-27 08:17 EDT",
		EstLandingTime:  "2019-10-27 11:11 PDT",
		ArrivalTime:     "2019-10-27 11:18 PDT",
	}
	got, err := getFlight(session, want.FlightNumber)
	if err != nil {
		t.Errorf("Wasn't expecting an error, but got one: %s", err)
		t.FailNow()
	}
	if !cmp.Equal(want, got) {
		t.Errorf("Expected: %+v\nGot: %+v", want, got)
	}
}
