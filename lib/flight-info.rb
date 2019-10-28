require 'httparty'
require 'capybara'
require 'capybara/dsl'
require 'capybara/apparition'
require 'json'
require 'timeout'

module FlightInfo
  def self.get(flight_number:)
    session = self.init_capybara
    url = ENV['FLIGHTAWARE_URL'] || "https://flightaware.com/live/flight/#{flight_number}"
    begin
      session.visit(url)
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
          flight_number: self.get_flight_number(session: session),
          origin: self.get_origin(session: session),
          destination: self.get_destination(session: session),
          departure_time: self.get_departure_time(session: session),
          est_takeoff_time: self.get_est_takeoff_time(session: session),
          est_landing_time: self.get_est_landing_time(session: session),
          arrival_time: self.get_arrival_time(session: session)
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

  def self.get_flight_number(session:)
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

  def self.get_destination(session:)
    origin_element = session.find('.flightPageSummaryAirports').find('.flightPageSummaryDestination')
    self.reload_element_if_obsolete! origin_element
    begin
      origin_element.text.split("\n").first
    rescue Exception => e
      raise "Could not get an origin: #{e}"
    end
  end

  # TODO
  def self.get_departure_time(session:)
    begin
      # NOTE: This will add latency.
      # Trying to find 'h3' matching 'Departure Times' didn't work.
      departure_time_element = session.all('.flightPageDataActualTimeText').first
      departure_date_element = session.find('.flightPageSummaryDepartureDay')
      self.reload_element_if_obsolete! departure_time_element
      self.reload_element_if_obsolete! departure_date_element
      depart_date = departure_date_element.text.strip
      depart_time = departure_time_element.text.split("\n").first.strip
      depart_timestring = [
        depart_date,
        depart_time
      ].join(' ')
      Time.parse(depart_timestring).to_i
    rescue Exception => e
      raise "Could not get a flight number: #{e}"
    end
  end

  def self.get_est_takeoff_time(session:)
    "08:18 EDT"
  end
  def self.get_est_landing_time(session:)
    "11:00 PDT"
  end
  def self.get_arrival_time(session:)
    "11:06 PDT"
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
