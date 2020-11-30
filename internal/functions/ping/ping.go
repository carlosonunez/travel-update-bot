package ping

// Ping is a simple function that ensures that flightaware-bot is working in Lambda.
func Ping() (string, error) {
	return "hello", nil
}
