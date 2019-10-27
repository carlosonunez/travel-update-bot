require 'httparty'
require 'capybara'
require 'capybara/dsl'
require 'capybara/apparition'
require 'json'
require 'timeout'

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

    self.wait_for_page_to_finish_loading!(session: session,
                                          timeout: 60)
    begin
      {
        statusCode: 200,
        body: {
          flight_number: self.find_flight_number_from_session(session: session),
          origin: self.get_origin(session: session)
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
    flight_number_element = session.find('.flightPageIdent')
    self.reload_element_if_obsolete! flight_number_element
    begin
      flight_number_element.text.split('/').first.strip
    rescue Exception => e
      raise "Could not get a flight number: #{e}"
    end
  end

  def self.get_origin(session:)
    origin_element = session.find('.flightPageSummaryAirports').find('.flightPageSummaryOrigin')
    self.reload_element_if_obsolete! origin_element
    begin
      origin_element.text.split("\n").first
    rescue Exception => e
      raise "Could not get an origin: #{e}"
    end
  end

  # The data shown on the FlightAware page may change out from under us
  # if it loads slowly.
  def self.reload_element_if_obsolete!(element)
    if element.to_s.match? 'Obsolete'
      element.reload
    end
  end

  # FlightAware can take a while to render its JSON data.
  # Wait for this to finish before continuing.
  def self.wait_for_page_to_finish_loading!(session:, timeout:)
    raise "Couldn't get current data" if timeout > 60
    Timeout::timeout(30) do
      loop do
        break if !session.find_all('.flightPageHeading').empty?
        sleep 0.5
      end
    end
  end
end
