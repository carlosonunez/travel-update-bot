package session

import (
	"errors"
	"fmt"
	"os"
	"strings"
	"time"

	log "github.com/sirupsen/logrus"

	"github.com/carlosonunez/flightaware_bot/internal/constants"
	"github.com/carlosonunez/flightaware_bot/internal/helpers"

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
	f.startLogging()
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

func (f *FlightAwareSession) startLogging() {
	log.SetOutput(os.Stdout)
	log.SetReportCaller(true)
	if level, ok := os.LookupEnv("LOG_LEVEL"); ok {
		switch strings.ToLower(level) {
		case "info":
			log.SetLevel(log.InfoLevel)
		case "warning":
			log.SetLevel(log.WarnLevel)
		case "error":
			log.SetLevel(log.FatalLevel)
		case "debug":
			selenium.SetDebug(true)
			log.SetLevel(log.DebugLevel)
		case "trace":
			selenium.SetDebug(true)
			log.SetLevel(log.TraceLevel)
		}
	}
}

func (f *FlightAwareSession) waitForPageToFinishLoading() error {
	foundElements := make(chan bool, 1)
	defer close(foundElements)

	go func() {
		elems, _ := f.remote.FindElements(selenium.ByClassName, "flightPageHeading")
		foundElements <- (len(elems) > 0)
	}()

	select {
	case <-foundElements:
		return nil
	case <-time.After(constants.FlightAwarePageTimeoutSeconds):
		return errors.New("Timed out while waiting for FlightAware to finish loading")
	}
}
