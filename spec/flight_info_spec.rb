require 'spec_helper'

describe "Test load" do
  it 'Should give me my nil page', :unit do
    expect(test_internet_access).to eq({
      body: {
        message: '<html><head></head><body><pre style="word-wrap: break-word; white-space: pre-wrap;">i love socks.</pre></body></html>'
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
    it "Retrieves flight info", :unit do
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
  end
end
