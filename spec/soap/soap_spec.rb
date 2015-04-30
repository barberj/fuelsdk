require 'spec_helper'

describe FuelSDK::Soap do

  let(:client) { FuelSDK::Client.new }

  subject { client }

  it { should respond_to(:soap_post) }
  it { should respond_to(:soap_patch) }
  it { should respond_to(:soap_delete) }
  it { should respond_to(:soap_describe) }
  it { should respond_to(:soap_perform) }

  it { should respond_to(:header) }
  it { should_not respond_to(:header=) }

  it { should respond_to(:wsdl) }
  it { should respond_to(:wsdl=) }

  it { should respond_to(:endpoint) }
  it { should respond_to(:endpoint=) }

  it { should respond_to(:soap_client) }

  its(:debug) { should be false }
  its(:wsdl) { should eq 'https://webservice.exacttarget.com/etframework.wsdl' }

  describe '#header' do
    it 'raises an exception when internal_token is missing' do
      expect { client.header }.to raise_exception 'Require legacy token for soap header'
    end

    it 'returns header hash' do
      client.internal_token = 'innerspace'
      expect(client.header).to eq(
        {
          'oAuth' => {
            'oAuthToken' => 'innerspace',
            '@xmlns' => 'http://exacttarget.com'
          }
        }
      )
    end
  end

  describe 'requests' do
    subject {
      client.stub(:soap_request) do |action, message|
        [action, message]
      end
      client
    }

    it '#soap_describe calls client with :describe and DescribeRequests message' do
      expect(subject.soap_describe 'Subscriber').to eq([:describe,
        {'DescribeRequests' => {'ObjectDefinitionRequest' => {'ObjectType' => 'Subscriber' }}}])
    end

    describe '#soap_post' do
      subject {
        client.stub(:soap_request) do |action, message|
          [action, message]
        end
        client.should_receive(:get_editable_properties)
          .and_return(['First Name', 'Last Name', 'Gender'])
        client
      }
      it 'formats soap :create message for single object' do
        expect(subject.soap_post 'Subscriber', 'EmailAddress' => 'test@fuelsdk.com' ).to eq([:create,
          {
            'Objects' => [{
              'EmailAddress' => 'test@fuelsdk.com',
              '@xsi:type'    => 'tns:Subscriber'
            }]
          }])
      end

      it 'formats soap :create message for multiple objects' do
        expect(subject.soap_post 'Subscriber', [{'EmailAddress' => 'first@fuelsdk.com'}, {'EmailAddress' => 'second@fuelsdk.com'}] ).to eq([:create,
          {
            'Objects' => [{
              'EmailAddress' => 'first@fuelsdk.com',
              '@xsi:type'    => 'tns:Subscriber'
            }, {
              'EmailAddress' => 'second@fuelsdk.com',
              '@xsi:type'    => 'tns:Subscriber'
            }]
          }])
      end

      it 'formats soap :create message for single object with an attribute' do
        expect(subject.soap_post 'Subscriber', {'EmailAddress' => 'test@fuelsdk.com',
          "First Name" => "first"}).to eq([:create,
          {
            'Objects' => [{
              'EmailAddress' => 'test@fuelsdk.com',
              'Attributes'   => [{'Name' => 'First Name', 'Value' => 'first'}],
              '@xsi:type'    => 'tns:Subscriber'
            }]
          }])
      end

      it 'formats soap :create message for single object with multiple attributes' do
        expect(subject.soap_post 'Subscriber', {'EmailAddress' => 'test@fuelsdk.com',
          "First Name" => "first", "Last Name" => "subscriber"}).to eq([:create,
          {
            'Objects' => [{
              'EmailAddress' => 'test@fuelsdk.com',
              'Attributes'   => [
                {'Name' => 'First Name', 'Value' => 'first'},
                {'Name' => 'Last Name', 'Value' => 'subscriber'},
              ],
              '@xsi:type'    => 'tns:Subscriber'
            }]
          }])
      end

      it 'formats soap :create message for multiple objects with multiple attributes' do
        expect(subject.soap_post 'Subscriber', [{'EmailAddress' => 'first@fuelsdk.com', "First Name" => "first", "Last Name" => "subscriber"},
          {'EmailAddress' => 'second@fuelsdk.com', "First Name" => "second", "Last Name" => "subscriber"}]).to eq([:create,
          {
            'Objects' => [
              {'EmailAddress' => 'first@fuelsdk.com',
                'Attributes'  => [
                  {'Name' => 'First Name', 'Value' => 'first'},
                  {'Name' => 'Last Name', 'Value' => 'subscriber'},
                ],
                '@xsi:type'    => 'tns:Subscriber'
              },
              {'EmailAddress' => 'second@fuelsdk.com',
                'Attributes' => [
                  {'Name' => 'First Name', 'Value' => 'second'},
                  {'Name' => 'Last Name', 'Value' => 'subscriber'},
                ],
                '@xsi:type'    => 'tns:Subscriber'
              }]
          }])
      end
    end
  end
end
