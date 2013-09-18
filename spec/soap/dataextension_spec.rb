require 'spec_helper'

describe FuelSDK::Soap do

  let(:client) { FuelSDK::Client.new }

  subject { client }

  describe '#format_cud_properties_for_dataextension' do
    let(:de_properties) {
      [{'CustomerKey' => 'Orders', 'total' => 1}]
    }
    it 'leaves CustomerKey alone an puts other attributes in name value pairs under Properies' do
      expect(client.format_dataextension_cud_properties de_properties).to eq([{
        'CustomerKey' => 'Orders',
         'Properties' => {'Property' => [{'Name' => 'total', 'Value' => 1}]}
       }])
    end
  end

end

