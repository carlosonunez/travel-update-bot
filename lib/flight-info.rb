require 'capybara'
require 'capybara/dsl'
require 'selenium-webdriver'
require 'json'
require 'timeout'
require 'time'
require 'httparty'

AIRLINE_SHORTCODE_MAP = {
  "AAL": 'AA',
  "DAL": 'DL',
  "UAL": 'UA'
}.freeze

# FlightInfo packs useful information from flight data
# into JSON and strips everything else.
module FlightInfo
  def self.ping
    {
      statusCode: 200,
      body: { message: 'hello' }.to_json
    }
  end

  def self.parse_flight_number(flight_number:)
    re = /^([A-Z]{2,3})([0-9]{1,4})$/
    matches = flight_number.match(re)
    raise if matches.nil?

    airline_shortcode = matches[1]
    flight = matches[2]
    return flight_number unless airline_shortcode.length == 3

    actual_shortcode = AIRLINE_SHORTCODE_MAP[airline_shortcode]
    raise "Invalid airline shortcode: #{airline_shortcode}" if actual_shortcode.nil?

    "#{actual_shortcode}#{flight}"
  end

  def self.test_internet_access
    response = {
      statusCode: 422,
      body: { message: 'fail' }.to_json
    }
    r = HTTParty.get('http://nil.carlosnunez.me', { timeout: 5 })
    if r.code == 200
      response[:statusCode] = 200
      response[:body] = { message: 'pass' }.to_json
    end
    response
  end

  def self.get_flight_details(flight_number_raw:)
    response = HTTParty.get("https://flightera.net/en/flight/#{flight_number}")
    {
      statusCode: 200,
      body: {
        flight_number: get_flight_number(response: response),
        origin: get_origin(response: response),
        origin_city: get_origin_city(response: response),
        destination: get_destination(response: response),
        destination_city: get_destination_city(response: response),
        departure_time: get_departure_time(response: response),
        est_takeoff_time: get_est_takeoff_time(response: response),
        est_landing_time: get_est_landing_time(response: response),
        arrival_time: get_arrival_time(response: response)
      }.to_json
    }
  rescue StandardError => e
    {
      statusCode: 422,
      body: {
        error: "Unable to retrieve flight info for #{flight_number}: #{e}"
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
  get_flight_time(response: response,
                  city_type: :origin,
                  gate_or_takeoff_time: :gate)
end

def self.get_est_takeoff_time(session:)
  takeoff_time = get_flight_time(response: response,
                                 city_type: :origin,
                                 gate_or_takeoff_time: :takeoff)
  return takeoff_time unless takeoff_time.nil?

  puts "WARN: Takeoff time not found. This can happen during delays. Defaulting to \
departure time."
  get_departure_time(response: response)
end

def self.get_est_landing_time(session:)
  landing_time = get_flight_time(response: response,
                                 city_type: :destination,
                                 gate_or_takeoff_time: :gate)
  return landing_time unless landing_time.nil?

  puts "WARN: Landing time not found. This can happen during delays. Defaulting to \
arrival time."
  get_arrival_time(response: response)
end

def self.get_arrival_time(session:)
  get_flight_time(response: response,
                  city_type: :destination,
                  gate_or_takeoff_time: :takeoff)
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
      break unless session.find_all('.flightPageSummaryMap').empty?

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
