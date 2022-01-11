# frozen_string_literal: true

require 'spec_helper'

def query_local_lambda(name, parameters)
  payload = if parameters.nil?
              '{}'
            else
              { "queryStringParameters": parameters }.to_json
            end
  HTTParty.post("http://integration-test-#{name}:8080/2015-03-31/functions/function/invocations",
                body: payload)
end

def query_actual_lambda(endpoint, parameters, method)
  parameters ||= {}
  method ||= :get
  HTTParty.send(method,
                "#{$api_gateway_url}/#{endpoint}",
                headers: { 'X-Api-Key' => $test_api_key },
                query: parameters)
end

def run_test_lambda_function(name:, parameters: {}, remote_endpoint: nil, method: :get)
  response = if ENV.key? 'USE_LOCAL_LAMBDA'
               query_local_lambda(name, parameters)
             else
               query_actual_lambda(remote_endpoint, parameters, method)
             end
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
    ping: {
      expected: {
        text: 'hello',
        match: :exact
      },
      remote_endpoint: 'ping'
    },
    test_internet_access: {
      expected: {
        text: 'i love socks',
        match: :contains
      },
      remote_endpoint: 'testInternetAccess'
    },
    test_flight_info: {
      expected: {
        key: 'flight_number'
      },
      remote_endpoint: 'flightInfo',
      remote_parameters: { 'flightNumber' => 'AAL1' }
    }
  }
  @functions.each do |function, properties|
    context "When we run the #{function} method" do
      example 'Then it should execute' do
        response = run_test_lambda_function(name: function,
                                            remote_endpoint: properties[:remote_endpoint],
                                            parameters: properties[:remote_parameters],
                                            method: properties[:remote_method])
        expect(response.code).to eq 200
        body = if ENV.key? 'USE_LOCAL_LAMBDA'
                 JSON.parse(JSON.parse(response.body)['body'])
               else
                 JSON.parse(response.body)
               end
        if properties.key? :expected
          if properties[:expected].key? :text
            want = properties[:expected][:text]
            if properties[:expected][:match] == :exact
              expect(body['message']).to eq want
            else
              expect(body['message']).to include want
            end
          elsif properties[:expected].key? :key
            expect(body).to include properties[:expected][:key]
          end
        end
      end
    end
  end
end
