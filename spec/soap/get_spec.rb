require 'spec_helper'

describe FuelSDK::Soap do

  let(:client) { FuelSDK::Client.new }
  subject { client }

  describe '#get_all_object_properties' do

    it 'returns properties for object_type' do
      response = mock(FuelSDK::DescribeResponse)
      response.should_receive(:success?).and_return(true)

      subject.should_receive(:soap_describe)
        .with('some object')
        .and_return(response)

      expect(subject.get_all_object_properties('some object'))
        .to eq response
    end

    it 'raises an DescribeError when describe is unsuccessful' do
      response = mock(FuelSDK::DescribeResponse)
      response.should_receive(:success?).and_return(false)
      response.stub(:status).and_return('ERROR')

      subject.should_receive(:soap_describe)
        .with('some object')
        .and_return(response)

      expect { subject.get_all_object_properties('some object') }
        .to raise_error FuelSDK::DescribeError
    end
  end

  describe '#normalize_properties' do
    it 'when properties are nil gets_all_object_properties' do
      subject.should_receive(:get_retrievable_properties)
        .with('object').and_return('called all')

      expect(subject.normalize_properties('object', nil)).to eq 'called all'
    end

    describe 'when properties is a' do
      subject {
        client.should_not_receive(:get_retrievable_properties)
        client
      }

      it 'Hash returns keys' do
        expect(subject.normalize_properties('object', {'Prop1' => 'a', 'Prop2' => 'b'}))
          .to eq ['Prop1', 'Prop2']
      end

      it 'String returns Array' do
        expect(subject.normalize_properties('object', 'Prop1'))
          .to eq ['Prop1']
      end

      it 'Symbol returns Array' do
        expect(subject.normalize_properties('object', :Prop1))
          .to eq ['Prop1']
      end

      it 'Array returns Array' do
        expect(subject.normalize_properties('object', ['Prop1']))
          .to eq ['Prop1']
      end
    end
  end

  describe '#normalize_filter' do
    it 'returns complex filter part when filter contains LogicalOperator key' do
      expect(subject.normalize_filter({'LogicalOperator' => 'AND'}))
        .to eq(
          {
            'Filter' => {
              'LogicalOperator' => 'AND',
              :attributes! => {
                'LeftOperand' => { 'xsi:type' => 'tns:SimpleFilterPart' },
                'RightOperand' => { 'xsi:type' => 'tns:SimpleFilterPart' }
              },
            },
            :attributes! => { 'Filter' => { 'xsi:type' => 'tns:ComplexFilterPart' }}
          }
        )
    end

    it 'returns simple filter part by default' do
      expect(subject.normalize_filter({'SimpleOperator' => 'equals'}))
        .to eq(
          {
            'Filter' => {
              'SimpleOperator' => 'equals',
            },
            :attributes! => { 'Filter' => { 'xsi:type' => 'tns:SimpleFilterPart' }}
          }
        )
    end

    it 'returns empty hash when no filter' do
      expect(subject.normalize_filter(nil)).to eq({})
    end

    it 'returns empty hash when filter is unparsable' do
      expect(subject.normalize_filter(['unparsable'])).to eq({})
    end
  end

  describe '#soap_get' do
    it 'request with message created with normalized properties, filters' do

      subject.should_receive(:normalize_properties)
        .with('end to end', nil).and_return([])

      subject.should_receive(:normalize_filter)
        .with(nil).and_return({})

      subject.should_receive(:create_object_type_message)
        .with('end to end', [], {}).and_return('message')

      subject.should_receive(:soap_request)
        .with(:retrieve, 'RetrieveRequest' => 'message')

      subject.soap_get 'end to end'
    end

    it 'request an object without passing properties or a filter' do

      subject.should_receive(:get_retrievable_properties)
        .with('no criteria').and_return(['Props1'])

      subject.should_not_receive(:add_complex_filter_part)
      subject.should_not_receive(:add_simple_filter_part)

      subject.should_receive(:soap_request).with(:retrieve, 'RetrieveRequest' => {
          'ObjectType' => 'no criteria',
          'Properties' => ['Props1']
        }
      )

      subject.soap_get 'no criteria'
    end

    it 'request an object with limited properties' do

      subject.should_not_receive(:get_retrievable_properties)
      subject.should_not_receive(:add_complex_fitler_part)
      subject.should_not_receive(:add_simple_fitler_part)

      subject.should_receive(:soap_request).with(:retrieve, 'RetrieveRequest' => {
          'ObjectType' => 'limited',
          'Properties' => ['Props1']
        }
      )

      subject.soap_get('limited', ['Props1'])
    end

    it 'request an invalid object without properties' do
      subject.should_receive(:get_retrievable_properties) { raise FuelSDK::DescribeError.new(
          FuelSDK::DescribeResponse.new,  "Unable to get invalid"
        )
      }

      rsp = subject.soap_get('invalid')
      expect(rsp.success?).to be_false
    end
  end

end
