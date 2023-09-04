#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift('./lib')
$LOAD_PATH.unshift('./vendor/bundle/gems/**/lib') if Dir.exist? './vendor'
require 'flight-info'

def test_chromium_launch(event: {}, context: {})
  message = <<-DEPRECATED_MESSAGE
  These functions no longer use Chromium for rendering and have been deprecated.
  DEPRECATED_MESSAGE
  { statusCode: 200, body: { message: message }.to_json }
end

def test_internet_access(event: {}, context: {})
  FlightInfo.test_internet_access
end

def get_ping(event: {}, context: {})
  FlightInfo.ping
end

def get_flight_info(event: {}, context: {})
  if event.empty? ||
     event['queryStringParameters'].nil? ||
     event['queryStringParameters']['flightNumber'].nil?
    return {
      statusCode: 422,
      body: { error: 'Missing flight number' }.to_json
    }
  end
  FlightInfo.flight_details(flight_number_raw: event['queryStringParameters']['flightNumber'])
end
