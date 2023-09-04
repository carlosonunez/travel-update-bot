require 'spec_helper'
require 'ostruct'

def fake_response(fixture_name)
  body = File.read("#{Dir.pwd}/spec/fixtures/#{fixture_name}.html")
  double(code: 200, body: body)
rescue StandardError => e
  raise "Failed to get test file for fixture #{fixture_name}: #{e}"
end

def get_test_flight(flight_number)
  fake_response("test_flight_#{flight_number.downcase}")
end

def get_test_airport_north_america(iata)
  fake_response("test_airport_k#{iata.downcase}")
end

describe 'Test load' do
  it 'Should give me my nil page', :unit do
    # This is easier than trying to test double Capybara since there's so
    # much monkey patching going on in there.
    fake_reply = 'bloop'
    fake_response = double(code: 200,
                           body: fake_reply)
    allow(SimpleTextBrowser).to receive(:get).and_return(fake_response)
    expect(FlightInfo.test_internet_access).to eq({
                                                    body: {
                                                      message: 'pass'
                                                    }.to_json,
                                                    statusCode: 200
                                                  })
  end
end

describe 'Flight info' do
  context 'When I ping it' do
    it 'Should ping back', :unit do
      expected_response = {
        body: { message: 'hello' }.to_json,
        statusCode: 200
      }
      expect(get_ping).to eq expected_response
    end
  end

  context 'When not given a flight number' do
    it 'Tells me that I need to provide a flight number', :unit do
      expect(get_flight_info).to eq({
                                      statusCode: 422,
                                      body: { error: 'Missing flight number' }.to_json
                                    })
    end
  end

  context 'When given a flight number' do
    it 'Retrieves flight info when all times are on the page', :unit do
      allow(SimpleTextBrowser).to receive(:get)
        .with("https://flightera.net/en/flight/AA1")
        .and_return(get_test_flight('AA1'))
      allow(SimpleTextBrowser).to receive(:post_form)
        .with("https://www.avcodes.co.uk/aptcoderes.asp",
              timeout: 5,
              body: "icaoapt=KJFK")
        .and_return(get_test_airport_north_america("JFK"))
      allow(SimpleTextBrowser).to receive(:post_form)
        .with("https://www.avcodes.co.uk/aptcoderes.asp",
              timeout: 5,
              body: "icaoapt=KLAX")
        .and_return(get_test_airport_north_america("LAX"))
      fake_event = JSON.parse({
        queryStringParameters: {
          flightNumber: 'AAL1'
        }
      }.to_json)
      expected_flight_info_json = {
        statusCode: 200,
        body: {
          flight_number: 'AAL1',
          origin: 'JFK',
          origin_city: 'New York, NY',
          destination: 'LAX',
          destination_city: 'Los Angeles, CA',
          departure_time: '2022-01-11 07:27 EST',
          est_takeoff_time: '2022-01-11 07:48 EST',
          est_landing_time: '2022-01-11 10:16 PST',
          arrival_time: '2022-01-11 10:34 PST'
        }.to_json
      }
      actual_json = get_flight_info(event: fake_event)
      expect(actual_json).to eq expected_flight_info_json
    end

    it "Approximates takeoff/landing times when they aren't known yet", :unit do
      ENV['FLIGHTAWARE_URL'] = "file:///#{Dir.pwd}/spec/fixtures/test_flight_aa356.html"
      fake_event = JSON.parse({
        queryStringParameters: {
          flightNumber: 'AAL356'
        }
      }.to_json)
      expected_flight_info_json = {
        statusCode: 200,
        body: {
          flight_number: 'AAL356',
          origin: 'PHX',
          origin_city: 'Phoenix, AZ',
          destination: 'DFW',
          destination_city: 'Dallas-Fort Worth, TX',
          departure_time: '2022-01-11 08:13 MST',
          est_takeoff_time: '2022-01-11 08:29 MST',
          est_landing_time: '2022-01-11 11:14 CST',
          arrival_time: '2022-01-11 11:28 CST'
        }.to_json
      }
      actual_json = get_flight_info(event: fake_event)
      expect(actual_json).to eq expected_flight_info_json
    end
  end
end
