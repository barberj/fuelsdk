require 'spec_helper'

describe FuelSDK::Soap do

  let(:client) { FuelSDK::Client.new }
  subject {client}

  it 'has inflector support' do
    expect('Definitions'.singularize).to eq 'Definition'
  end

  describe '#create_action_message' do
    it 'returns message' do
      expect(subject.create_action_message('Definitions', 'QueryDefinition', [{'ObjectID' => 1}], 'start'))
        .to eq(
        {
          'Action' => 'start',
          'Definitions' => {
            'Definition' => [{'ObjectID' => 1}],
            :attributes! => {
              'Definition' => { 'xsi:type' => 'tns:QueryDefinition'}
            }
          }
        }
      )
    end

    it 'standardizes properties to an array' do
      expect(subject.create_action_message('Definitions', 'QueryDefinition', {'ObjectID' => 1}, 'start'))
        .to eq(
        {
          'Action' => 'start',
          'Definitions' => {
            'Definition' => [{'ObjectID' => 1}],
            :attributes! => {
              'Definition' => { 'xsi:type' => 'tns:QueryDefinition'}
            }
          }
        }
      )
    end
  end

  describe '#soap_perform' do
    it 'starts a defined query' do
      subject.should_receive(:create_action_message)
        .with('Definitions', 'QueryDefinition', [{'ObjectID' => 1}], 'start')
        .and_return 'Do It'
      subject.should_receive(:soap_request).with(:perform, 'Do It')
      subject.soap_perform 'QueryDefinition', [{'ObjectID' => 1}], 'start'
    end
  end
end
