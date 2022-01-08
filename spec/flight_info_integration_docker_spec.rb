# frozen_string_literal: true

require 'spec_helper'

describe 'Given an instance of Flight Info that runs on Docker', :integration_docker do
  before(:all) do
    if `docker images | grep flight-info-integration-app`.empty?
      system('docker build -t flight-info-integration-app .') \
        or raise 'Unable to build Docker image for integration testing'
    end
  end
  after(:all) do
    `docker rmi -f flight-info-integration-app`
  end
  context "When we run the 'ping' method" do
    example 'Then it should execute' do
      expect(`docker run --rm flight-info-integration-app ./bin/ping.rb ./spec/fixtures/test_ping.html`)
        .to eq 'bloop'
    end
  end
end
