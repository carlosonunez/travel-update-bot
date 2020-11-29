package session

import (
	"errors"
	"fmt"
	"io"
	"os"
	"time"

	"github.com/carlosonunez/flightaware_bot/internal/constants"
	"github.com/carlosonunez/flightaware_bot/internal/helpers"
	"github.com/carlosonunez/flightaware_bot/internal/logging"

	log "github.com/sirupsen/logrus"

	"github.com/tebeka/selenium"
	"github.com/tebeka/selenium/firefox"
)

// FlightAwareSession stores details about the webdriver
// being used to capture details from flightaware.com.
type FlightAwareSession struct {
	remote          selenium.WebDriver
	service         *selenium.Service
	flightAwarePage string
}

// NewSession creates a new session.
func NewSession(baseURL string, flightID string) *FlightAwareSession {
	logging.Start()
	service, capabilities := newHeadlessFirefoxService()
	remote, err := selenium.NewRemote(capabilities, "http://localhost:4444")
	if err != nil {
		panic(err)
	}
	return &FlightAwareSession{
		flightAwarePage: fmt.Sprintf("%s/%s", baseURL, flightID),
		service:         service,
		remote:          remote,
	}
}

// Close closes an existing session.
func (f *FlightAwareSession) Close() error {
	return f.service.Stop()
}

// Load is a convenience method for browsing to the FlightAware page set by Initialize.
func (f *FlightAwareSession) Load() error {
	log.Debugf("About to fetch %s", f.flightAwarePage)
	if err := f.remote.Get(f.flightAwarePage); err != nil {
		return err
	}
	return f.waitForPageToFinishLoading()
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

func newHeadlessFirefoxService() (*selenium.Service, selenium.Capabilities) {
	capabilities := selenium.Capabilities{}
	var outputDevice io.Writer
	if log.GetLevel() == log.DebugLevel || log.GetLevel() == log.TraceLevel {
		outputDevice = os.Stderr
	}
	service, err := selenium.NewGeckoDriverService("/usr/local/bin/geckodriver",
		4444,
		selenium.Output(outputDevice))
	if err != nil {
		panic(err)
	}
	capabilities.AddFirefox(firefox.Capabilities{
		Binary: "/usr/local/bin/firefox",
		Args:   []string{"--headless"},
	})
	return service, capabilities
}
