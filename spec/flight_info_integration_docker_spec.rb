# frozen_string_literal: true

require 'spec_helper'
require 'uri'

describe 'Given an instance of Flight Info that runs on Docker', :integration_docker do
  context "When we run the 'ping' method" do
    example 'Then it should execute' do
      response =
        HTTParty.post('http://integration-test-ping:8080/2015-03-31/functions/function/invocations')
      expect(response.code).to eq 200
      expect(response.body).to eq 'bloop'
    end
  end
end
