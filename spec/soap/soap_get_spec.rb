require 'spec_helper'

describe FuelSDK::Soap do
  describe '#get' do

    let(:client) { FuelSDK::Client.new }
    subject { client }
    it { should respond_to(:soap_get) }

    describe 'called without properties' do

    end
  end
end
