require 'spec_helper'

describe FuelSDK::Soap do

  let(:client) { FuelSDK::Client.new }

  describe '#normalize_object_properties' do
    it 'when properties are nil gets_all_object_properties' do
      client.stub(:get_all_object_properties)
        .and_return('called all')
      client.should_receive(:get_all_object_properties)
        .with('object')

      expect(client.normalize_object_properties('object', nil)).to eq 'called all'
    end

    it 'when properties is a Hash returns keys' do
      expect(client.normalize_object_properties('object', {'Prop1' => 'a', 'Prop2' => 'b'}))
        .to eq ['Prop1', 'Prop2']
    end

    it 'when properties is a String returns Array' do
      expect(client.normalize_object_properties('object', 'Prop1'))
        .to eq ['Prop1']
    end
  end

  describe '#normalize_message_filter' do
    it 'adds complex filter part when filter contains LogicalOperator key' do
      expect(client.normalize_message_filter({'message' => 'hi'}, {'LogicalOperator' => 'AND'}))
        .to eq(
          {
            'RetrieveRequest' => {
              'message' => 'hi',
              'Filter' => {
                'LogicalOperator' => 'AND',
                :attributes! => {
                  'LeftOperand' => { 'xsi:type' => 'tns:SimpleFilterPart' },
                  'RightOperand' => { 'xsi:type' => 'tns:SimpleFilterPart' }
                },
              },
              :attributes! => { 'Filter' => { 'xsi:type' => 'tns:ComplexFilterPart' }}
            }
          }
        )
    end

    it 'adds simple filter part by default' do
      expect(client.normalize_message_filter({'message' => 'hi'}, {'SimpleOperator' => 'equals'}))
        .to eq(
          {
            'RetrieveRequest' => {
              'message' => 'hi',
              'Filter' => {
                'SimpleOperator' => 'equals',
              },
              :attributes! => { 'Filter' => { 'xsi:type' => 'tns:SimpleFilterPart' }}
            }
          }
        )
    end
  end

  describe '#soap_get' do
  end

end
