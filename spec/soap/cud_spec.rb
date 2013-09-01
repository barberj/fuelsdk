require 'spec_helper'

describe FuelSDK::Soap do

  let(:client) { FuelSDK::Client.new }

  subject { client }

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
  end

end
