package selectors

const (
	// EstOriginDepartureTime is the time that the flight is scheduled to leave the gate.
	EstOriginDepartureTime = 0

	// EstOriginTakeoffTime is the time that the flight is scheduled to take off.
	EstOriginTakeoffTime = 1

	// EstDestinationLandingTime is the time that the flight is forecasted to
	// land at its destination airport's runway.
	EstDestinationLandingTime = 2

	// EstDestinationArrivalTime is the time that the flight is scheduled to arrive
	// at the gate at its destination.
	EstDestinationArrivalTime = 3

	// AirportIATA is the IATA of the origin airport.
	AirportIATA = 0

	// OriginFlightDate is the flight's origin date.
	OriginFlightDate = 2

	// DestinationFlightDate is the flight's date at its destination.
	DestinationFlightDate = 1
)
