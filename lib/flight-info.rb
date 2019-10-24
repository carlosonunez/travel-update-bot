require 'httparty'
require 'capybara'
require 'capybara/dsl'
require 'capybara/apparition'
require 'json'

module FlightInfo
  def self.get(flight_number:)
    session = self.init_capybara
    begin
      session.visit("https://flightaware.com/live/flight/#{flight_number}")
    rescue Exception => e
      return {
        statusCode: 400,
        body: {
          error: "Unable to retrieve flight info for #{flight_number}: #{e}"
        }.to_json
      }.to_json
    end

    begin
      {
        statusCode: 200,
        body: {
          flight_number: self.find_flight_number_from_session(session: session)
        }.to_json
      }.to_json
    rescue Exception => e
      return {
        statusCode: 400,
        body: {
          error: "Unable to find flight details for #{flight_number}: #{e}"
        }.to_json
      }.to_json
    end
  end

  private
  def self.init_capybara
    Capybara.register_driver :apparition do |app|
      opts = {
        headless: true,
        browser_options: [
          :no_sandbox,
          { disable_features: 'VizDisplayCompositor' },
          :disable_gpu
        ]
      }
      Capybara::Apparition::Driver.new(app, opts)
    end
    Capybara.default_driver = :apparition
    Capybara.javascript_driver = :apparition
    Capybara::Session.new :apparition
  end

  def self.find_flight_number_from_session(session:)
    flight_number_element = session.find_all('.flightPageIdent')
    require 'pry'
    binding.pry
    raise "We couldn't find a flight number" if flight_number_element.empty?
    raise "Too many flight numbers found" if flight_number_element.length != 1
    flight_number_element.first.text.split('/')[1].strip
  end
end
