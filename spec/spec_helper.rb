require 'rspec'
require 'json'
require 'httparty'
require_relative '../bin/flight-info'
Dir.glob("#{Dir.pwd}/spec/helpers/**/*.rb") do |file|
  require_relative file
end

RSpec.configure do |config|
  config.before(:all, integration: true) do
    $api_gateway_url = ENV['API_GATEWAY_URL'] || Helpers::Integration::HTTP.get_endpoint
    if $api_gateway_url.nil? or $api_gateway_url.empty?
      raise "Please define API_GATEWAY_URL as an environment variable or \
run 'docker-compose run --rm integration-setup'"
    end

    $test_api_key =
      Helpers::Integration::SharedSecrets.read_secret(secret_name: 'api_key') ||
      raise('Please create the "api_key" secret.')
  end
end
