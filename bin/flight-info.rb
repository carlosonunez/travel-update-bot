#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift('./lib')
$LOAD_PATH.unshift('./vendor/bundle/gems/**/lib') if Dir.exist? './vendor'
require 'flight-info'

def test_chromium_launch(event: {}, context: {})
  args = FlightInfo::CHROMIUM_ARGS.map { |arg| arg.prepend('--') }
                                  .map { |arg| arg.gsub('----', '--') }
                                  .join(' ')
  output = `2>&1 chromium #{args} https://flightaware.com`
  rc = $CHILD_STATUS
  { statusCode: 200, body: { message: "rc: #{rc}, opts: #{args}, output: #{output}" }.to_json }
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
  FlightInfo.get_flight_details(flight_number: event['queryStringParameters']['flightNumber'])
end
