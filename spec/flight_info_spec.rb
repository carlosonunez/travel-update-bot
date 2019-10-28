require 'spec_helper'

describe "Flight info" do
  context "When I ping it" do
    it 'Should ping back', :unit do
      expected_response = {
        body: { message: 'hello' }.to_json,
        statusCode: 200
      }
      expect(FlightInfo.ping).to eq expected_response
    end
  end
  context "When given a flight number" do
    it "Retrieves flight info", :unit do
      ENV['FLIGHTAWARE_URL'] = "file:///#{Dir.pwd}/spec/fixtures/test_flight_aa1.html"
      expected_flight_info_json = {
        statusCode: 200,
        body: {
          flight_number: "AAL1",
          origin: "JFK",
          destination: "LAX",
          departure_time: "2019-10-27 07:53 EDT",
          est_takeoff_time: "2019-10-27 08:17 EDT",
          est_landing_time: "2019-10-27 11:11 PDT",
          arrival_time: "2019-10-27 11:18 PDT"
        }.to_json
      }
      actual_json = JSON.parse(FlightInfo.get(flight_number: 'AA1'),
                               {symbolize_names: true})
      expect(actual_json).to eq expected_flight_info_json
    end
  end
end
