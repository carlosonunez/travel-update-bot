#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift('./lib')
$LOAD_PATH.unshift('./vendor/bundle/gems/**/lib') if Dir.exist? './vendor'
require 'flight-info'

def test_chromium_launch(event: {}, context: {})
  args = FlightInfo::CHROMIUM_ARGS.map { |arg| arg.prepend('--') }
                                  .map { |arg| arg.gsub('----', '--') }
                                  .join(' ')
  args += ' --remote-debugging-port=9222 --disable-software-rasterizer'
  args += ' --diasable-gpu-process-prelaunch --disable-gpu-sandbox'
  args += ' -v=99'
  output = `2>&1 timeout 25 chromium #{args}`
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
  if event.empty? or
     event['queryStringParameters'].nil? or
     event['queryStringParameters']['flightNumber'].nil?
    return {
      statusCode: 422,
      body: { error: 'Missing flight number' }.to_json
    }
  end
  FlightInfo.get_flight_details(flight_number: event['queryStringParameters']['flightNumber'])
end
