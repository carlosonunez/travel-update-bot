require 'spec_helper'

describe "Flight info" do
  context "When given a flight number" do
    it "Retrieves flight info", :unit, :vcr do
      stub_request(:get, "www.flightaware.com").to_return(
                        body: File.read("spec/fixtures/test_flight_aa1.html")
      )
      expected_flight_info_json = {
        flight_number: "AAL1",
        origin: "JFK",
        destination: "LAX",
        departure_time: "07:54 EDT",
        est_takeoff_time: "08:18 EDT",
        est_landing_time: "11:00 PDT",
        arrival_time: "11:06 PDT"
      }.to_json
      expect(FlightInfo.get(flight_number: 'AA1')).to eq({
        statusCode: 200,
        body: expected_flight_info_json
      }.to_json)
    end
  end
end
