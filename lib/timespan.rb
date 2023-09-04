# Timespan provides helper functions for calculating durations from strings.
module TimeSpan
  UNITS = {
    m: 60,
    h: 60 * 60,
    d: 60 * 60 * 24
  }.freeze

  def self.to_sec(str:)
    pattern = /^([0-9]{1,})([a-z]{1})$/
    result = 0
    str.split(' ').each do |token|
      matches = str.match(pattern) or raise "Invalid token: #{token}"

      span = matches[1]
      unit = matches[2]
      raise "Invalid duration unit: #{unit}" unless UNITS.key? unit.to_sym

      result += span * UNITS[unit.to_sym]
    end
    result
  end
end
