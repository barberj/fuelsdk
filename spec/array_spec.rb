require 'spec_helper'

describe Array do

  it '#self.wrap returns subject wrapped in an array' do
    expect(Array.wrap(1)).to eq([1])
  end

  it '#self.wrap returns subject as is when already wrapped' do
    expect(Array.wrap([1])).to eq([1])
  end
end
