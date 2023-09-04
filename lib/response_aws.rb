require 'json'

# AWSResponse handles generating response JSONs that are compatible
# with the AWS Lambda runtime.
module AWSResponse
  def self.success(body:, code: 200)
    {
      statusCode: code,
      body: body.to_json
    }
  end

  def self.fail(message:)
    {
      statusCode: 422,
      body: {
        error: message
      }.to_json
    }
  end
end
