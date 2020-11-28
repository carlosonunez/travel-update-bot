package logging

import (
	"os"
	"strings"

	"github.com/sirupsen/logrus"
	log "github.com/sirupsen/logrus"
)

// Start creates a singleton Stdout logger for all to enjoy. Thread-safe.
func Start() {
	log.SetOutput(os.Stdout)
	log.SetReportCaller(true)
	if level, ok := os.LookupEnv("LOG_LEVEL"); ok {
		switch strings.ToLower(level) {
		case "info":
			log.SetLevel(logrus.InfoLevel)
		case "warning":
			log.SetLevel(logrus.WarnLevel)
		case "error":
			log.SetLevel(logrus.FatalLevel)
		case "debug":
			log.SetLevel(logrus.DebugLevel)
		case "trace":
			log.SetLevel(logrus.TraceLevel)
		}
	}
}
