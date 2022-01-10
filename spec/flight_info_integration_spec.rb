# frozen_string_literal: true

require 'spec_helper'

def run_test_lambda_function(name:, payload: '{}')
  url = if ENV.key? 'USE_LOCAL_LAMBDA'
          service_name = "integration-test-#{name}"
          "http://#{service_name}:8080/2015-03-31/functions/function/invocations"
        else
          "#{$api_gateway_url}/#{name}"
        end
  response = HTTParty.post(url, body: payload)
  if response.body.empty? && ENV.key?('USE_LOCAL_LAMBDA')
    raise <<~ERROR
      The Lambda Runtime Interface Client returned an empty response.
      This usually indicates that it died while trying to parse the function's payload.
      Check the logs from the #{service_name} Docker service then restart it:
      'docker-compose restart #{service_name}'
    ERROR
  end

  response
end

describe 'Flight Info Bot Health', :integration do
  @functions = {
    ping: 'hello',
    test_internet_access: '<html><head></head><body><pre style="word-wrap: break-word; white-space: pre-wrap;">i love socks.</pre></body></html>',
    test_chromium_launch: ''
  }
  @functions.each do |function, want|
    context "When we run the #{function} method" do
      example 'Then it should execute' do
        response = run_test_lambda_function(name: function)
        expect(response.code).to eq 200
        expect(JSON.parse(response.body)['statusCode']).to eq 200
        expect(JSON.parse(JSON.parse(response.body)['body'])['message']).to eq want unless want.empty?
      end
    end
  end
end
