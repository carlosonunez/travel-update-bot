require 'spec_helper'
require 'ostruct'

describe "Test load" do
  it 'Should give me my nil page', :unit do
    # This is easier than trying to test double Capybara since there's so
    # much monkey patching going on in there.
    fake_reply = 'bloop'
    fake_session = double("Fake session",
                          visit: true,
                          body: fake_reply)
    allow(FlightInfo).to receive(:init_capybara).and_return(fake_session)
    expect(test_internet_access).to eq({
      body: {
        message: fake_reply
      }.to_json,
      statusCode: 200
    })
  end
end

describe "Flight info" do
  context "When I ping it" do
    it 'Should ping back', :unit do
      expected_response = {
        body: { message: 'hello' }.to_json,
        statusCode: 200
      }
      expect(get_ping).to eq expected_response
    end
  end

  context "When not given a flight number" do
    it "Tells me that I need to provide a flight number", :unit do
      expect(get_flight_info).to eq({
        statusCode: 422,
        body: { error: "Missing flight number" }.to_json
      })
    end
  end

  context "When given a flight number" do
    it "Retrieves flight info when all times are on the page", :unit do
      ENV['FLIGHTAWARE_URL'] = "file:///#{Dir.pwd}/spec/fixtures/test_flight_aa1.html"
      fake_event = JSON.parse({
        queryStringParameters: {
          flightNumber: "AAL1"
        }
      }.to_json)
      expected_flight_info_json = {
        statusCode: 200,
        body: {
          flight_number: "AAL1",
          origin: "JFK",
          origin_city: "New York, NY",
          destination: "LAX",
          destination_city: "Los Angeles, CA",
          departure_time: "2019-10-27 07:53 EDT",
          est_takeoff_time: "2019-10-27 08:17 EDT",
          est_landing_time: "2019-10-27 11:11 PDT",
          arrival_time: "2019-10-27 11:18 PDT"
        }.to_json
      }
      actual_json = get_flight_info(event: fake_event)
      expect(actual_json).to eq expected_flight_info_json
    end

    it "Approximates takeoff/landing times when they aren't known yet", :unit do
      ENV['FLIGHTAWARE_URL'] = "file:///#{Dir.pwd}/spec/fixtures/test_flight_aa356.html"
      fake_event = JSON.parse({
        queryStringParameters: {
          flightNumber: "AAL356"
        }
      }.to_json)
      expected_flight_info_json = {
        statusCode: 200,
        body: {
          flight_number: "AAL356",
          origin: "OMA",
          origin_city: "Omaha, NE",
          destination: "DFW",
          destination_city: "Dallas-Fort Worth, TX",
          departure_time: "2019-11-07 20:23 CST",
          est_takeoff_time: "2019-11-07 20:23 CST",
          est_landing_time: "2019-11-07 22:20 CST",
          arrival_time: "2019-11-07 22:20 CST"
        }.to_json
      }
      actual_json = get_flight_info(event: fake_event)
      expect(actual_json).to eq expected_flight_info_json
    end
  end
end
