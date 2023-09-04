require 'spec_helper'

describe 'Time spans' do
  it 'Should return seconds if span valid', :unit do
    expect(TimeSpan.to_sec('60m')).to_return(3600)
  end

  it 'Should return seconds if span has multiple tokens', :unit do
    expect(TimeSpan.to_sec('3h 30m')).to_return(12_600)
  end
end
