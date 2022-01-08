# frozen_string_literal: true

# !/usr/bin/env ruby
$LOAD_PATH.unshift('./lib')
$LOAD_PATH.unshift('./vendor/bundle/gems/**/lib') if Dir.exist? './vendor'
require 'flight-info'

# rubocop: disable Lint/UnusedMethodArgument
def get_flight_info(event: {}, context: {})
  if event.empty? ||
     event['queryStringParameters'].nil? ||
     event['queryStringParameters']['flightNumber'].nil?
    return {
      statusCode: 422,
      body: { error: 'Missing flight number' }.to_json
    }
  end
  FlightInfo.get_flight_details(flight_number: event['queryStringParameters']['flightNumber'])
end
# rubocop: enable Lint/UnusedMethodArgument
