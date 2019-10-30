require 'rspec'
require 'capybara'
require 'capybara/dsl'
require 'chromedriver-helper'
require 'selenium-webdriver'
require 'json'
require_relative '../bin/flight-info.rb'
Dir.glob('/app/spec/helpers/**/*.rb') do |file|
  require_relative file
end


RSpec.configure do |config|
  config.include Capybara::DSL, :integration => true
  config.before(:all, :integration => true) do
    ['SELENIUM_HOST', 'SELENIUM_PORT'].each do |required_selenium_env_var|
      raise "Please set #{required_selenium_env_var}" if ENV[required_selenium_env_var].nil?
    end

    $api_gateway_url = ENV['API_GATEWAY_URL'] || Helpers::Integration::HTTP.get_endpoint
    raise "Please define API_GATEWAY_URL as an environment variable or \
run 'docker-compose run --rm integration-setup'" \
      if $api_gateway_url.nil? or $api_gateway_url.empty?

    $test_api_key =
      Helpers::Integration::SharedSecrets.read_secret(secret_name: 'api_key') ||
        raise('Please create the "api_key" secret.')

    Capybara.run_server = false
    Capybara.register_driver :selenium do |app|
      Capybara::Selenium::Driver.new(
        app,
        browser: :remote,
        url: "http://#{ENV['SELENIUM_HOST']}:#{ENV['SELENIUM_PORT']}/wd/hub",
        desired_capabilities: Selenium::WebDriver::Remote::Capabilities.chrome(
          "chromeOptions" => {
            "args" => ['--no-default-browser-check']
          }
        )
      )
    end
    Capybara.default_driver = :selenium
  end
end
