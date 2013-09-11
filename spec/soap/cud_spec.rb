require 'spec_helper'

describe FuelSDK::Soap do

  let(:client) { FuelSDK::Client.new }

  subject { client }

  describe '#editable_properties_cached?' do
    it 'returns a list of editable properties for the object' do
      subject.should_receive(:cached_properties?)
        .with(:editable, 'item')
        .and_return(['prop'])

      expect(subject.editable_properties_cached? 'item').to eq(['prop'])
    end

    it 'returns nil if not cached' do
      expect(subject.editable_properties_cached? 'missing').to be_nil
    end
  end

  describe '#get_editable_properties' do
    it 'returns cached properties' do
      subject.should_receive(:editable_properties_cached?)
        .with('object')
        .and_return(['prop'])

      subject.should_not_receive(:get_all_object_properties)
      subject.should_not_receive(:cache_editable)

      expect(subject.get_editable_properties('object')).to eq ['prop']
    end

    it 'requests and caches properties when not in cache' do
      subject.should_receive(:editable_properties_cached?)
        .with('object')
        .and_return(nil)

      response = double(FuelSDK::DescribeResponse)
      response.stub(:editable).and_return(['prop'])
      subject.should_receive(:get_all_object_properties)
        .and_return(response)

      subject.should_receive(:cache_editable)
        .with('object', ['prop'])
        .and_return(['prop'])

      expect(subject.get_editable_properties('object')).to eq ['prop']
    end
  end

  describe '#cache_editable' do
    it 'caches object properties to :editable' do
      subject.cache_editable('Subscriber', ['Email'])
      expect(subject.cache[:editable]).to eq 'Subscriber' => ['Email']
    end
  end

  describe '#normalize_properties_for_cud' do

    it 'creates soap objects properties hash putting ' \
      'custom attributes into name value pairs' do

      subject.should_receive(:get_editable_properties)
        .with('Subscriber')
        .and_return(['FirstName'])

      expect(subject.normalize_properties_for_cud(
        'Subscriber',
        [{'Email' => 'dev@exacttarget.com', 'FirstName' => 'Devy'}]
      )).to eq(
          [{
            'Email' => 'dev@exacttarget.com',
            'Attributes' => [{'Name' => 'FirstName', 'Value' => 'Devy'}]
          }]
      )
    end

    it 'converts properties into an array' do
      subject.should_receive(:get_editable_properties)
        .with('Subscriber')
        .and_return(['FirstName'])

      expect(subject.normalize_properties_for_cud(
        'Subscriber',
        {'Email' => 'dev@exacttarget.com', 'FirstName' => 'Devy'}
      )).to eq(
          [{
            'Email' => 'dev@exacttarget.com',
            'Attributes' => [{'Name' => 'FirstName', 'Value' => 'Devy'}]
          }]
      )
    end

    it 'raises an exception if properties are not a hash' do
      expect { subject.normalize_properties_for_cud('Subscriber', 'Email') }
        .to raise_error
    end
  end

  describe '#create_objects_message' do
    it 'creates hash for soap message' do
      obj_attributes = [{'Name' => 'First Name', 'Value' => 'Justin'}]
      expect(subject.create_objects_message('object', obj_attributes)).to eq(
          {
            'Objects' => [{'Name' => 'First Name', 'Value' => 'Justin'}],
            :attributes! => {'Objects' => { 'xsi:type' => 'tns:object' }}
          }
      )
    end

    it 'raises an exception if object attributes is not an Array' do
      expect{ subject.create_objects_message('object', '1') }.to raise_error
    end

    it 'raises an exception if object attributes are not stored in a hash' do
      expect{ subject.create_objects_message('object', ['1']) }.to raise_error
    end
  end

  describe '#soap_cud' do
    it 'request with message created with normalized properties' do

      subject.should_receive(:normalize_properties_for_cud)
      subject.should_receive(:create_objects_message)
      subject.should_receive(:soap_request)

      subject.send :soap_cud, :post, 'Subscriber', [{'EmailAddress' => 'dev@exacttarget.com'}]
    end
  end
end
