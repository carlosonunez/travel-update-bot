package session

import (
	"errors"
	"fmt"
	"time"

	"github.com/carlosonunez/flightaware_bot/internal/constants"
	"github.com/carlosonunez/flightaware_bot/internal/helpers"
	"github.com/carlosonunez/flightaware_bot/internal/logging"

	log "github.com/sirupsen/logrus"

	"github.com/tebeka/selenium"
)

// FlightAwareSession stores details about the webdriver
// being used to capture details from flightaware.com.
type FlightAwareSession struct {
	remote          selenium.WebDriver
	flightAwarePage string
}

// Initialize starts up the selenium WebDriver and prepares it
// to browse flightaware.com.
func (f *FlightAwareSession) Initialize(flightNumber string) {
	logging.Start()
	f.flightAwarePage = fmt.Sprintf("%s/%s",
		constants.FlightAwareBaseUrl,
		flightNumber)
}

// FindElementsByClassName returns the innerText of elements matching a class name
// or an error if unable to find it.
func (f *FlightAwareSession) FindElementsByClassName(class string) ([]string, error) {
	elems, err := f.remote.FindElements(selenium.ByXPATH, fmt.Sprintf("//*[@class='%s']", class))
	if err != nil {
		return nil, err
	}
	texts := make([]string, len(elems))
	for i, x := range elems {
		texts[i] = helpers.StringMust(x.Text())
	}
	log.Debugf("Sought %s, got %+v", class, texts)
	return texts, nil
}

// Load is a convenience method for browsing to the FlightAware page set by Initialize.
func (f *FlightAwareSession) Load() error {
	log.Debugf("About to fetch %s", f.flightAwarePage)
	if err := f.remote.Get(f.flightAwarePage); err != nil {
		return err
	}
	return f.waitForPageToFinishLoading()
}

func (f *FlightAwareSession) waitForPageToFinishLoading() error {
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
