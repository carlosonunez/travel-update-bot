require 'json'
require 'timeout'
require 'time'
require 'httparty'
require 'nokogiri'
require 'response_aws'

AIRLINE_SHORTCODE_MAP = {
  "aal": 'aa',
  "dal": 'dl',
  "ual": 'ua'
}.freeze

# TODO: Move this into its own file somewhere.
class SimpleTextBrowser
  attr_accessor :code
  attr_accessor :body

  def self.get(url, timeout = 0, additional_headers = {})
    base_headers = {
      'User-Agent': 'PostmanRuntime/7.26.0',
    }
    headers = base_headers.merge(additional_headers)
    puts "headers: #{headers}"
    r = HTTParty.get(url,
                 timeout: timeout,
                 headers: headers)
    @code = r.code
    @body = r.body
  end

  def self.post_form(url, body, timeout = 0, additional_headers = {})
    base_headers = {
      "Content-Type": "application/x-www-form-urlencoded",
      'User-Agent': 'PostmanRuntime/7.26.0',
      'charset': 'utf-8'
    }
    headers = base_headers.merge(additional_headers)
    r = HTTParty.post(url,
                 timeout: timeout,
                 headers: headers,
                 body: body)
    @code = r.code
    @body = r.body
  end
end

# FlightInfo packs useful information from flight data
# into JSON and strips everything else.
module FlightInfo
  def self.ping
    {
      statusCode: 200,
      body: { message: 'hello' }.to_json
    }
  end

  def self.parse_flight_number_exn!(flight_number:)
    re = /^([A-Z]{2,3})([0-9]{1,4})$/
    matches = flight_number.match(re)
    raise if matches.nil?

    airline_shortcode = matches[1]
    return flight_number unless airline_shortcode.length == 3

    flight = matches[2]
    actual_shortcode = AIRLINE_SHORTCODE_MAP[airline_shortcode.downcase.to_sym]
    raise "Invalid airline shortcode: #{airline_shortcode}" if actual_shortcode.nil?

    "#{actual_shortcode.upcase}#{flight}"
  end

  def self.test_internet_access
    response = {
      statusCode: 422,
      body: { message: 'fail' }.to_json
    }
    r = SimpleTextBrowser.get('http://nil.carlosnunez.me', timeout: 5)
    if r.code == 200
      response[:statusCode] = 200
      response[:body] = { message: 'pass' }.to_json
    end
    response
  end

  def self.flight_details(flight_number_raw:)
    flight_number = parse_flight_number_exn!(flight_number: flight_number_raw)
    response = SimpleTextBrowser.get("https://flightera.net/en/flight/#{flight_number}")
    raise "Flight not found: #{flight_number}" if response.code == 404
    AWSResponse.success(body: flight_info_from_html(response.body))
  rescue StandardError => e
    puts "stack trace; #{e.backtrace}"
    AWSResponse.fail(message: "Unable to get flight details for #{flight_number_raw}: #{e}")
  end

  def self.flight_info_from_html(html)
    doc = Nokogiri::HTML(html)
    origin_icao = origin(doc: doc)
    dest_icao = destination(doc: doc)
    {
      flight_number: flight_number(doc: doc),
      origin: origin_icao,
      origin_city: icao_to_location(icao: origin_icao),
      destination: dest_icao,
      destination_city: icao_to_location(icao: dest_icao),
      departure_time: departure_time(doc: doc),
      est_takeoff_time: est_takeoff_time(doc: doc),
      est_landing_time: est_landing_time(doc: doc),
      arrival_time: arrival_time(doc: doc)
    }
  end

  def self.flight_number(doc:)
    node = doc.xpath("//h1[contains(@class, 'text-center')]")
    raise 'Flight number not found' if node.nil?

    node.text.gsub(/^.*\((.*)\)$/, '\1').strip!
  end

  def self.origin(doc:)
    nodes = doc.xpath("//a[contains(@title, 'All Details for') and contains(@href, '/airport/')]")
    raise "Couldn't find originating airport" if nodes.nil? || nodes.length.zero?

    airport_ref = nodes[0].attributes['href'].text
    expected_pattern = %r{^/en/airport}
    raise "Not a valid originating airport ref: #{airport_ref}" unless airport_ref.match? expected_pattern

    airport_ref.split('/')[-1]
  end

  def self.destination(doc:)
    nodes = doc.xpath("//a[contains(@title, 'All Details for') and contains(@href, '/airport/')]")
    raise "Couldn't find destination airport" if nodes.nil? || nodes.length < 2

    airport_ref = nodes[1].attributes['href'].text
    expected_pattern = %r{^/en/airport}
    raise "Not a valid destination airport ref: #{airport_ref}" unless airport_ref.match? expected_pattern

    airport_ref.split('/')[-1]
  end

  def self.icao_to_location(icao:)
    r = SimpleTextBrowser.post_form('https://www.avcodes.co.uk/aptcoderes.asp',
                      timeout: 5,
                      body: "icaoapt=#{icao}")
    raise "Unable to locate airport: #{icao}" if r.code == 500
    raise "Invalid airport identifier: #{icao}" if r.body.match? 'There is currently no Airport'

    doc = Nokogiri::HTML(r.body)
    city = doc.xpath("//td[contains(text(), 'Location Name:')]")
    raise "Couldn't find city from airport: #{icao}" if city.nil? || city.length.zero?

    state = doc.xpath("//td[contains(text(), 'State / Province:')]")
    raise "Couldn't find state from airport: #{icao}" if state.nil? || state.length.zero?

    "#{city.text.split(':')[-1]}, #{state.text.split(':')[-1]}"
  end

  def self.departure_time(doc:)
    this_month = Date.today.strftime("%b")
    date_nodes = doc.xpath("//*[contains(text(), '#{this_month}')]")
    raise "Couldn't find departure date or flight found is not for this month" if date_nodes.nil? || date_nodes.length.zero?

    date_str = date_nodes[0].text.strip!

    time_nodes = doc.xpath("//*[text()='Departure']")
    raise "Couldn't find departure time" if time_nodes.nil? || time_nodes.length.zero?
    time_str = time_nodes[0].next_element.text.strip!.gsub("\n", ' ')
    Time.parse("#{date_str} #{time_str}")
  end

  def self.est_takeoff_time(doc:)
    dep_time = departure_time(doc: doc)
    nodes = doc.xpath("//*[text()='Departure']")
    raise "Couldn't find departure time" if nodes.nil? || nodes.length.zero?

    status = nodes[0].parent.parent.text.strip!.split("\n")[-1].strip.downcase
    case status
    when /^\+/
      offset = status.gsub(/^\+([0-9]{1,}) ([a-z]).*/,'\1\2').strip
    end
  end

  def self.est_landing_time(session:)
    landing_time = flight_time(response: response,
                               city_type: :destination,
                               gate_or_takeoff_time: :gate)
    return landing_time unless landing_time.nil?

    puts "WARN: Landing time not found. This can happen during delays. Defaulting to \
    arrival time."
    arrival_time(response: response)
  end

  def self.arrival_time(session:)
    flight_time(response: response,
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
  def self.flight_time(session:,
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
