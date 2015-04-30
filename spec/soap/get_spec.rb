require 'spec_helper'

describe FuelSDK::Soap do

  let(:client) { FuelSDK::Client.new }
  subject { client }

  describe '#get_all_object_properties' do

    it 'returns properties for object_type' do
      response = double(FuelSDK::DescribeResponse)
      response.should_receive(:success?).and_return(true)

      subject.should_receive(:soap_describe)
        .with('some object')
        .and_return(response)

      expect(subject.get_all_object_properties('some object'))
        .to eq response
    end

    it 'raises an DescribeError when describe is unsuccessful' do
      response = double(FuelSDK::DescribeResponse)
      response.should_receive(:success?).and_return(false)
      response.stub(:status).and_return('ERROR')

      subject.should_receive(:soap_describe)
        .with('some object')
        .and_return(response)

      expect { subject.get_all_object_properties('some object') }
        .to raise_error FuelSDK::DescribeError
    end
  end

  describe '#normalize_properties_for_retrieve' do
    it 'when properties are nil gets_all_object_properties' do
      subject.should_receive(:get_retrievable_properties)
        .with('object').and_return('called all')

      expect(subject.normalize_properties_for_retrieve('object', nil)).to eq 'called all'
    end

    describe 'when properties is a' do
      subject {
        client.should_not_receive(:get_retrievable_properties)
        client
      }

      it 'Hash returns keys' do
        expect(subject.normalize_properties_for_retrieve('object', {'Prop1' => 'a', 'Prop2' => 'b'}))
          .to eq ['Prop1', 'Prop2']
      end

      it 'String returns Array' do
        expect(subject.normalize_properties_for_retrieve('object', 'Prop1'))
          .to eq ['Prop1']
      end

      it 'Symbol returns Array' do
        expect(subject.normalize_properties_for_retrieve('object', :Prop1))
          .to eq ['Prop1']
      end

      it 'Array returns Array' do
        expect(subject.normalize_properties_for_retrieve('object', ['Prop1']))
          .to eq ['Prop1']
      end
    end
  end

  describe '#normalize_filter' do
    it 'returns complex filter part when filter contains LogicalOperator key' do
      expect(subject.normalize_filter({'LogicalOperator' => 'AND', 'LeftOperand' => {}, 'RightOperand' => {}}))
        .to eq(
          {
            'Filter' => {
              'LogicalOperator' => 'AND',
              '@xsi:type'       => 'tns:ComplexFilterPart',
              'LeftOperand'     => { '@xsi:type' => 'tns:SimpleFilterPart' },
              'RightOperand'    => { '@xsi:type' => 'tns:SimpleFilterPart' }
            }
          }
        )
    end

    it 'raises error when missing left or right operand' do
      expect{subject.normalize_filter({'LogicalOperator' => 'AND'})}
        .to raise_error /Missing SimpleFilterParts/
    end

    it 'returns simple filter part by default' do
      expect(subject.normalize_filter({'SimpleOperator' => 'equals'}))
        .to eq(
          {
            'Filter' => {
              'SimpleOperator' => 'equals',
              '@xsi:type'      => 'tns:SimpleFilterPart',
            }
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

  describe '#cache_properties' do
    it 'raise an error if properties is not an Array' do

      subject.should_not_receive(:cache)
      expect { subject.cache_properties :retrievable, 'Subscriber', 'EmailAddress' }
        .to raise_error
    end

    it 'caches properties' do
      subject.should_receive(:cache).and_return({:retrievable => {}})
      expect(subject.cache_properties :retrievable, 'Subscriber', ['EmailAddress'])
        .to eq(['EmailAddress'])
    end
  end

  describe '#cached_properties?' do
    it 'returns cached properties' do
      subject.should_receive(:cache).and_return(
        {
          :retrievable => {
          'Subscriber' => ['EmailAddress']}
        }
      )

      expect(subject.cached_properties?(:retrievable, 'Subscriber'))
        .to eq ['EmailAddress']
    end

    it 'returns nil on error access cache' do
      subject.should_receive(:cache).and_return(1)
      expect(subject.cached_properties?(:retrievable, 'Subscriber'))
        .to be_nil
    end
  end

  describe '#retrievable_properties_cached?' do
    it 'returns a list of retrievable properties for the object' do
      subject.should_receive(:cached_properties?)
        .with(:retrievable, 'item')
        .and_return(['prop'])

      expect(subject.retrievable_properties_cached? 'item').to eq(['prop'])
    end

    it 'returns nil if not cached' do
      expect(subject.retrievable_properties_cached? 'missing').to be_nil
    end
  end

  describe '#get_retrievable_properties' do
    it 'returns cached properties' do
      subject.should_receive(:retrievable_properties_cached?)
        .with('object')
        .and_return(['prop'])

      subject.should_not_receive(:get_all_object_properties)
      subject.should_not_receive(:cache_retrievable)

      expect(subject.get_retrievable_properties('object')).to eq ['prop']
    end

    it 'requests and caches properties when not in cache' do
      subject.should_receive(:retrievable_properties_cached?)
        .with('object')
        .and_return(nil)

      response = double(FuelSDK::DescribeResponse)
      response.stub(:retrievable).and_return(['prop'])
      subject.should_receive(:get_all_object_properties)
        .and_return(response)

      subject.should_receive(:cache_retrievable)
        .with('object', ['prop'])
        .and_return(['prop'])

      expect(subject.get_retrievable_properties('object')).to eq ['prop']
    end
  end

  describe '#cache_retrievable' do
    it 'caches object properties to :retrievable' do
      subject.cache_retrievable('Subscriber', ['Email'])
      expect(subject.cache[:retrievable]).to eq 'Subscriber' => ['Email']
    end
  end

  describe '#soap_get' do
    it 'request with message created with normalized properties, filters' do

      subject.should_receive(:normalize_properties_for_retrieve)
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
      expect(rsp.success?).to be false
    end
  end

  describe '#normalize_customer_key' do
    it 'changes CustomerKey to DataExtension.CustomerKey' do
      expect(client.normalize_customer_key({'Property' => 'CustomerKey'}, 'DataExtensionField'))
        .to eq({'Property' => 'DataExtension.CustomerKey'})
    end

    it 'nothing changes if object is not a DataExtension' do
      expect(client.normalize_customer_key({'Property' => 'CustomerKey'}, 'SomethingObject'))
        .to eq({'Property' => 'CustomerKey'})
    end
  end

end
