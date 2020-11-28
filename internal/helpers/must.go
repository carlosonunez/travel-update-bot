package helpers

import (
	log "github.com/sirupsen/logrus"
)

// StringMust throws away the error of a multi-valued return and returns the item you wanted
func StringMust(s string, err error) string {
	if err != nil {
		log.Error(err)
	}
	return s
}
