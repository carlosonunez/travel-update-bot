package mocks

import (
	"errors"
	"fmt"
	"os"
	"time"

	"github.com/carlosonunez/flightaware_bot/internal/constants"
	"github.com/carlosonunez/flightaware_bot/internal/helpers"
	"github.com/carlosonunez/flightaware_bot/internal/logging"
	log "github.com/sirupsen/logrus"
	"github.com/tebeka/selenium"
)

// MockFlightAwareSessionInterface mocks session.FlightAwareSessionInterface
type MockFlightAwareSessionInterface interface {
	Initialize(string)
	Load() error
}

// MockFlightAwareSession is used to send fake pages over to our headless
// browser. This is done to avoid network calls and spammy behavior.
type MockFlightAwareSession struct {
	remote          selenium.WebDriver
	flightAwarePage string
}

// Initialize starts our headless browser at our fake page.
func (f *MockFlightAwareSession) Initialize(flightNumber string) {
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

// Load is the same as session.FlightAwareSession::Load().
func (f *MockFlightAwareSession) Load() error {
	log.Debugf("About to load: %s", f.flightAwarePage)
	if err := f.remote.Get(f.flightAwarePage); err != nil {
		return err
	}
	return f.waitForPageToFinishLoading()
}

// FindElementsByClassName is the same as session.FlightAwareSession::FindElementsByClassName
func (f *MockFlightAwareSession) FindElementsByClassName(id string) ([]string, error) {
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
func (f *MockFlightAwareSession) waitForPageToFinishLoading() error {
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
