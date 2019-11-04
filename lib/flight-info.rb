require 'capybara'
require 'capybara/dsl'
require 'capybara/poltergeist'
require 'json'
require 'timeout'
require 'time'

module FlightInfo
  def self.ping
    {
      statusCode: 200,
      body: {message: 'hello'}.to_json
    }
  end

  def self.test_internet_access
    session = self.init_capybara
    session.visit('http://nil.carlosnunez.me')
    {
      statusCode: 200,
      body: { message: session.body }.to_json
    }
  end

  def self.get_flight_details(flight_number:)
    session = self.init_capybara
    url = ENV['FLIGHTAWARE_URL'] || "https://flightaware.com/live/flight/#{flight_number}"
    begin
      session.visit(url)
    rescue Exception => e
      return {
        statusCode: 422,
        body: {
          error: "Unable to retrieve flight info for #{flight_number}: #{e}"
        }.to_json
      }
    end

    self.wait_for_page_to_finish_loading!(session: session,
                                          timeout: 60)
    begin
      {
        statusCode: 200,
        body: {
          flight_number: self.get_flight_number(session: session),
          origin: self.get_origin(session: session),
          origin_city: self.get_origin_city(session: session),
          destination: self.get_destination(session: session),
          destination_city: self.get_destination_city(session: session),
          departure_time: self.get_departure_time(session: session),
          est_takeoff_time: self.get_est_takeoff_time(session: session),
          est_landing_time: self.get_est_landing_time(session: session),
          arrival_time: self.get_arrival_time(session: session)
        }.to_json
      }
    rescue Exception => e
      return {
        statusCode: 422,
        body: {
          error: "Unable to find flight details for #{flight_number}: #{e}"
        }.to_json
      }
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

  def self.get_origin_city(session:)
    origin_element = session.all('.flightPageSummaryCity').first
    self.reload_element_if_obsolete! origin_element
    begin
      origin_element['innerHTML'].strip
    rescue Exception => e
      raise "Could not get an origin: #{e}"
    end
  end

  def self.get_destination_city(session:)
    origin_element = session.find('.destinationCity')
    self.reload_element_if_obsolete! origin_element
    begin
      origin_element['innerHTML'].strip
    rescue Exception => e
      raise "Could not get an origin: #{e}"
    end
  end

  def self.get_departure_time(session:)
    self.get_flight_time(session: session,
                         city_type: :origin,
                         gate_or_takeoff_time: :gate)
  end

  def self.get_est_takeoff_time(session:)
    self.get_flight_time(session: session,
                         city_type: :origin,
                         gate_or_takeoff_time: :takeoff)
  end

  def self.get_est_landing_time(session:)
    self.get_flight_time(session: session,
                         city_type: :destination,
                         gate_or_takeoff_time: :gate)
  end
  def self.get_arrival_time(session:)
    self.get_flight_time(session: session,
                         city_type: :destination,
                         gate_or_takeoff_time: :takeoff)
  end

  private
  def self.init_capybara
    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app, {
        phantomjs: '/opt/phantomjs/phantomjs',
        js_errors: false,
        phantomjs_options: [
          '--ssl-protocol=any',
          '--load-images=no',
          '--ignore-ssl-errors=yes'
        ]
      })
    end
    Capybara.default_driver = :poltergeist
    Capybara.javascript_driver = :poltergeist
    Capybara::Session.new :poltergeist
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

  # Fortunately, retrieving departure and arrival dates
  # is this straighforward.
  def self.get_flight_time(session:,
                           city_type:,
                           gate_or_takeoff_time:)
    date_element_map = {
      origin: {
        date: '.flightPageSummaryDepartureDay',
        gate: 0,
        takeoff: 1
      },
      destination: {
        date: '.flightPageSummaryArrivalDay',
        gate: 2,
        takeoff: 3
      }
    }
    begin
      # NOTE: This will add latency.
      # Trying to find 'h3' matching 'Departure Times' didn't work.
      time_element_pos = date_element_map[city_type][gate_or_takeoff_time]
      time_element =
        session.all('.flightPageDataActualTimeText')[time_element_pos]
      date_element =
        session.find(date_element_map[city_type][:date])
      self.reload_element_if_obsolete! time_element
      self.reload_element_if_obsolete! date_element
      date = Time.parse(date_element.text.strip).strftime("%F")

      # FlightAware uses non-standard timezones. Capture them directly from
      # the page instead of trying to convert them.
      time_full = time_element.text.split("\n").first.strip
      time = Time.parse(time_full.split(' ').first).strftime("%R")
      flightaware_timezone = time_full.split(' ').last
      [date,time,flightaware_timezone].join(' ')
    rescue Exception => e
      raise "Failed to retrieve travel time: #{e}. Here is the date that we saw; \
this might help for debugging purposes: #{date_element}, #{time_element}"
    end
  end
end
