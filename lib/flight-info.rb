require 'capybara'
require 'capybara/dsl'
require 'selenium-webdriver'
require 'json'
require 'timeout'
require 'time'

module FlightInfo
  CHROMIUM_ARGS = %w[headless
                     enable-features=NetworkService,NetworkServiceInProcess
                     no-sandbox
                     disable-dev-shm-usage
                     disable-gpu]
  def self.ping
    {
      statusCode: 200,
      body: { message: 'hello' }.to_json
    }
  end

  def self.test_internet_access
    session = init_capybara
    session.visit('http://nil.carlosnunez.me')
    {
      statusCode: 200,
      body: { message: session.body }.to_json
    }
  end

  def self.get_flight_details(flight_number:)
    session = init_capybara
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

    wait_for_page_to_finish_loading!(session: session,
                                     timeout: 60)
    begin
      {
        statusCode: 200,
        body: {
          flight_number: get_flight_number(session: session),
          origin: get_origin(session: session),
          origin_city: get_origin_city(session: session),
          destination: get_destination(session: session),
          destination_city: get_destination_city(session: session),
          departure_time: get_departure_time(session: session),
          est_takeoff_time: get_est_takeoff_time(session: session),
          est_landing_time: get_est_landing_time(session: session),
          arrival_time: get_arrival_time(session: session)
        }.to_json
      }
    rescue Exception => e
      {
        statusCode: 422,
        body: {
          error: "Unable to find flight details for #{flight_number}: #{e}"
        }.to_json
      }
    end
  end

  def self.get_flight_number(session:)
    flight_number_element = session.find('.flightPageIdent')
    reload_element_if_obsolete! flight_number_element
    begin
      flight_number_element.text.split('/').first.strip
    rescue Exception => e
      raise "Could not get a flight number: #{e}"
    end
  end

  def self.get_origin(session:)
    origin_element = session.find('.flightPageSummaryAirports').find('.flightPageSummaryOrigin')
    reload_element_if_obsolete! origin_element
    begin
      origin_element.text.split("\n").first
    rescue Exception => e
      raise "Could not get an origin: #{e}"
    end
  end

  def self.get_destination(session:)
    origin_element = session.find('.flightPageSummaryAirports').find('.flightPageSummaryDestination')
    reload_element_if_obsolete! origin_element
    begin
      origin_element.text.split("\n").first
    rescue Exception => e
      raise "Could not get an origin: #{e}"
    end
  end

  def self.get_origin_city(session:)
    origin_element = session.all('.flightPageSummaryCity').first
    reload_element_if_obsolete! origin_element
    begin
      origin_element['innerHTML'].strip
    rescue Exception => e
      raise "Could not get an origin: #{e}"
    end
  end

  def self.get_destination_city(session:)
    origin_element = session.find('.destinationCity')
    reload_element_if_obsolete! origin_element
    begin
      origin_element['innerHTML'].strip
    rescue Exception => e
      raise "Could not get an origin: #{e}"
    end
  end

  def self.get_departure_time(session:)
    get_flight_time(session: session,
                    city_type: :origin,
                    gate_or_takeoff_time: :gate)
  end

  def self.get_est_takeoff_time(session:)
    takeoff_time = get_flight_time(session: session,
                                   city_type: :origin,
                                   gate_or_takeoff_time: :takeoff)
    return takeoff_time unless takeoff_time.nil?

    puts "WARN: Takeoff time not found. This can happen during delays. Defaulting to \
departure time."
    get_departure_time(session: session)
  end

  def self.get_est_landing_time(session:)
    landing_time = get_flight_time(session: session,
                                   city_type: :destination,
                                   gate_or_takeoff_time: :gate)
    return landing_time unless landing_time.nil?

    puts "WARN: Landing time not found. This can happen during delays. Defaulting to \
arrival time."
    get_arrival_time(session: session)
  end

  def self.get_arrival_time(session:)
    get_flight_time(session: session,
                    city_type: :destination,
                    gate_or_takeoff_time: :takeoff)
  end

  def self.init_capybara
    Capybara.register_driver :headless_chrome do |app|
      caps = ::Selenium::WebDriver::Remote::Capabilities.chrome(
        "goog:chromeOptions": {
          args: CHROMIUM_ARGS
        }
      )

      Capybara::Selenium::Driver.new(app,
                                     browser: :chrome,
                                     capabilities: caps)
    end

    Selenium::WebDriver.logger.level = :debug
    Capybara.default_driver = :headless_chrome
    Capybara.javascript_driver = :headless_chrome
    Capybara::Session.new :headless_chrome
  end

  # The data shown on the FlightAware page may change out from under us
  # if it loads slowly.
  def self.reload_element_if_obsolete!(element)
    element.reload if element.to_s.match? 'Obsolete'
  end

  # FlightAware can take a while to render its JSON data.
  # Wait for this to finish before continuing.
  def self.wait_for_page_to_finish_loading!(session:, timeout:)
    raise "Couldn't get current data" if timeout > 60

    Timeout.timeout(30) do
      loop do
        break unless session.find_all('.flightPageHeading').empty?

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
      reload_element_if_obsolete! time_element
      reload_element_if_obsolete! date_element
      serialized_date = date_element.text.strip
      serialized_time = time_element.text.split("\n").first.strip
      if serialized_time == '--' or serialized_date == '--'
        puts 'WARN: Invalid date/time combo detected'
        return nil
      end
      date = Time.parse(serialized_date).strftime('%F')

      # FlightAware uses non-standard timezones. Capture them directly from
      # the page instead of trying to convert them.
      time = Time.parse(serialized_time.split(' ').first).strftime('%R')
      flightaware_timezone = serialized_time.split(' ').last
      [date, time, flightaware_timezone].join(' ')
    rescue Exception => e
      raise "Failed to retrieve travel time: #{e}. Here is the date that we saw; \
this might help for debugging purposes: #{serialized_date}, #{serialized_time}"
    end
  end
end
