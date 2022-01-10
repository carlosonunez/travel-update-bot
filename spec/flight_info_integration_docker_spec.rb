# Why do we need this?
#
# PhantomJS stopped rendering FlightAware sometime in 2020. Consequently, we now
# have to use Chromium to scrape it.
#
# Unfortunately, fitting Chromium inside of a Lambda layer is challenging, and even if you manage
# to get it to fit (and writing your own JIT decompression routine since you'll likely use
# Brotli like the chrome-lambda Node project is doing), testing it locally is tough unless
# you're using the lambci/lambda Docker image (which only works for x86_64 architectures...
# more on that later).
#
# Fortunately, Lambda can now spawn Docker containers from OCI-compliant images in ECR. This
# is a god-send for local testing, as you can now execute your code in the same environment
# as what it will run in on the real thing. However, executing functions through the
# Lambda Interface Emulator is not as straightforward as running them through ruby since
# you're actually executing them like Lambda functions (i.e. through a handler invoked via HTTP).
#
# This series of tests confirms that:
#
# - The RIE and its requisite client are set up correctly, and
# - That Selenium can talk to the instance of Chromium that's installed in our base image
#   through the RIE.

# frozen_string_literal: true

require 'spec_helper'
require 'uri'

def run_test_lambda_function(name:, payload: '{}')
  service_name = "integration-test-#{name}"
  url = "http://#{service_name}:8080/2015-03-31/functions/function/invocations"
  response = HTTParty.post(url, body: payload)
  if response.body.empty?
    raise <<~ERROR
      The Lambda Runtime Interface Client returned an empty response.
      This usually indicates that it died while trying to parse the function's payload.
      Check the logs from the #{service_name} Docker service then restart it:
      'docker-compose restart #{service_name}'
    ERROR
  end

  response
end

describe 'Given an instance of Flight Info that runs on Docker', :integration_docker do
  @functions = {
    ping: 'hello',
    test_internet_access: '<html><head></head><body><pre style="word-wrap: break-word; white-space: pre-wrap;">i love socks.</pre></body></html>'
  }
  @functions.each do |function, want|
    context "When we run the #{function} method" do
      example 'Then it should execute' do
        response = run_test_lambda_function(name: function)
        expect(response.code).to eq 200
        expect(JSON.parse(response.body)['statusCode']).to eq 200
        expect(JSON.parse(JSON.parse(response.body)['body'])['message']).to eq want
      end
    end
  end
end
