require 'capybara'
require 'capybara/dsl'
require 'selenium-webdriver'
require 'vcr'
require 'webmock'

VCR.configure do |vcr|
  vcr.cassette_library_dir = 'spec/cassettes'
  vcr.hook_info = :webmock
  vcr.configure_rspec_metadata!
end
