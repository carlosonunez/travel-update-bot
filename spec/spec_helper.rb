require 'rspec'
require 'flight-info'
require 'httparty'
require 'capybara'
require 'capybara/dsl'
require 'selenium-webdriver'
require 'webmock'
require 'webmock/rspec'
Dir.glob('/app/spec/helpers/**/*.rb') do |file|
  require_relative file
end


RSpec.configure do |config|
  config.include Capybara::DSL, :integration => true
  config.before(:all, :unit => true) do
    include WebMock::API
    WebMock.enable!
  end
  config.before(:all, :integration => true) do
    ['SELENIUM_HOST', 'SELENIUM_PORT'].each do |required_selenium_env_var|
      raise "Please set #{required_selenium_env_var}" if ENV[required_selenium_env_var].nil?
    end

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
