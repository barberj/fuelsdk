require 'spec_helper'

describe FuelSDK::SoapError do

  it { should respond_to(:response) }

  let (:triggering) { FuelSDK::SoapResponse.new }

  it 'has passed message as error' do
    error = FuelSDK::SoapError.new(triggering, 'i am an error message')
    expect(error.message).to eq 'i am an error message'
  end

  it 'triggering response is available' do
    error = FuelSDK::SoapError.new(triggering, 'i am an error message')
    expect(error.response).to eq triggering
  end

  it 'sets message on response' do
    expect(triggering.message).to be_nil
    error = FuelSDK::SoapError.new(triggering, 'i am an error message')
    expect(triggering.message).to eq 'i am an error message'
  end

end
