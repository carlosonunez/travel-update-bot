# flight-info

Grabs flight info from FlightAware. Written during a flight, so sorry for the
lack of tests.

# How does it work?

```sh
$: curl 'https://{your_domain}/v1/flight_info?flight_number=AA1'
{
  "flight_number": "AAL1";
  "origin": "JFK";
  "destination": "LAX";
  "departure_time": "07:54 EDT";
  "est_takeoff_time": "08:18 EDT";
  "est_landing_time": "11:00 PDT";
  "arrival_time": "11:06 PDT"
}
```
