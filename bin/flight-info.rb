#!/usr/bin/env ruby
require 'flight-info'

def get_ping(event: {}, context: {})
  FlightInfo::ping
end

def get_flight_info(event: {}, context: {})
  if event['queryParameters'].nil? or event['queryParameters']['flightNumber'].nil?
    {
      statusCode: 400,
      body: { error: "Missing flight number" }.to_json
    }.to_json
  end
  FlightInfo.get(flight_number: event['queryParameters']['flightNumber'])
end
