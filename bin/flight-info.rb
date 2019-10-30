#!/usr/bin/env ruby
$LOAD_PATH.unshift('./lib')
if Dir.exist? './vendor'
  $LOAD_PATH.unshift('./vendor/bundle/gems/**/lib')
end
require 'flight-info'

def test_internet_access(event: {}, context: {})
  FlightInfo::test_internet_access
end

def get_ping(event: {}, context: {})
  FlightInfo::ping
end

def get_flight_info(event: {}, context: {})
  if (event.empty? or
      event['queryStringParameters'].nil? or
      event['queryStringParameters']['flightNumber'].nil?)
    return {
      statusCode: 422,
      body: { error: "Missing flight number" }.to_json
    }
  end
  FlightInfo::get_flight_details(flight_number: event['queryStringParameters']['flightNumber'])
end
