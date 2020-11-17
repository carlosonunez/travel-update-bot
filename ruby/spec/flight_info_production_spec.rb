require 'spec_helper'

describe 'Flight Info Bot Health', :production do
  it 'Should be up' do
    response = Net::HTTP.get_response URI()
  end
end
