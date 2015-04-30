require 'spec_helper'

describe FuelSDK::Client do

  it { should respond_to :cache }

  describe '#cache' do
    let(:client) { FuelSDK::Client.new }

    it 'its default keys are retrievable and editable' do
      expect(client.cache).to eq({:retrievable => {}, :editable => {}})
    end
  end

  context 'initialized' do

    it 'with client parameters' do
      client = FuelSDK::Client.new 'client' => { 'id' => '1234', 'secret' => 'ssssh', 'signature' => 'hancock' }
      expect(client.secret).to eq 'ssssh'
      expect(client.id).to eq '1234'
      expect(client.signature).to eq 'hancock'
    end

    it 'with debug=true' do
      client = FuelSDK::Client.new({}, true)
      expect(client.debug).to be true
    end

    it 'with debug=false' do
      client = FuelSDK::Client.new({}, false)
      expect(client.debug).to be false
    end

    it 'creates SoapClient' do
      client = FuelSDK::Client.new
      expect(client).to be_kind_of FuelSDK::Soap
    end

    it '#wsdl defaults to https://webservice.exacttarget.com/etframework.wsdl' do
      client = FuelSDK::Client.new
      expect(client.wsdl).to eq 'https://webservice.exacttarget.com/etframework.wsdl'
    end

    it 'creates RestClient' do
      client = FuelSDK::Client.new
      expect(client).to be_kind_of FuelSDK::Rest
    end

    describe 'with a wsdl' do

      let(:client) { FuelSDK::Client.new 'defaultwsdl' => 'somewsdl' }

      it'creates a SoapClient' do
        expect(client).to be_kind_of FuelSDK::Soap
      end

      it'#wsdl returns default wsdl' do
        expect(client.wsdl).to eq 'somewsdl'
      end
    end
  end

  context 'instance can set' do

    let(:client) { FuelSDK::Client.new }

    it 'client id' do
      client.id = 123
      expect(client.id).to eq 123
    end

    it 'client secret' do
      client.secret = 'sssh'
      expect(client.secret).to eq 'sssh'
    end

    it 'refresh token' do
      client.refresh_token = 'refresh'
      expect(client.refresh_token).to eq 'refresh'
    end

    it 'debug' do
      expect(client.debug).to be false
      client.debug = true
      expect(client.debug).to be true
    end
  end

  describe '#jwt=' do

    let(:payload) {
     {
      'request' => {
        'user'=> {
          'oauthToken' => 123456789,
          'expiresIn' => DateTime.new(2001, 01, 01),
          'internalOauthToken' => 987654321,
          'refreshToken' => 101010101010
        }
      }
     }
    }

    let(:sig){
      sig = 'hanckock'
    }

    let(:encoded) {
      JWT.encode(payload, sig)
    }

    it 'raises an exception when signature is missing' do
      expect { FuelSDK::Client.new.jwt = encoded }.to raise_exception 'Require app signature to decode JWT'
    end

    describe 'decodes JWT' do

      let(:sig){
        sig = 'hanckock'
      }

      let(:encoded) {
        JWT.encode(payload, sig)
      }

      let(:client) {
        FuelSDK::Client.new 'client' => { 'id' => '1234', 'secret' => 'ssssh', 'signature' => sig }
      }

      it 'making auth token available to client' do
        client.jwt = encoded
        expect(client.auth_token).to eq 123456789
      end

      it 'making internal token available to client' do
        client.jwt = encoded
        expect(client.internal_token).to eq 987654321
      end

      it 'making refresh token available to client' do
        client.jwt = encoded
        expect(client.refresh_token).to eq 101010101010
      end
    end
  end

  describe '#refresh_token' do
    let(:client) { FuelSDK::Client.new }

    it 'defaults to nil' do
      expect(client.refresh_token).to be_nil
    end

    it 'can be accessed' do
      client.refresh_token = '1234567890'
      expect(client.refresh_token).to eq '1234567890'
    end
  end

  describe '#refresh' do

    let(:client) { FuelSDK::Client.new }

    it 'does nothing if auth_token exists' do
      client.should_receive(:auth_token).and_return(true)
      client.should_not_receive(:clear_client!)
      client.refresh
    end

    describe 'requests and sets new tokens' do
      subject {
        client.should_receive(:request_token_data)
        client.should_receive(:request_token_options).and_return('options')
        client.should_receive(:post)
          .with("https://auth.exacttargetapis.com/v1/requestToken", 'options')
          .and_return 'accessToken' => :access,
            'legacyToken' => :legacy,
            'refreshToken' => :refresh
        client
      }
      it 'calls #clear_client!' do
        subject.instance_variable_set '@soap_client', 'SOAP'
        expect(subject.instance_variable_get '@soap_client').to eq 'SOAP'
        subject.refresh
        expect(subject.instance_variable_get '@soap_client').to be_nil
      end
      it 'sets auth_token' do
        subject.refresh
        expect(subject.auth_token).to eq :access
      end
      it 'sets internal_token' do
        subject.refresh
        expect(subject.internal_token).to eq :legacy
      end
      it 'sets refresh_token' do
        subject.refresh
        expect(subject.refresh_token).to eq :refresh
      end

      it 'sets auth_token when forced and auth_token is present' do
        subject.auth_token = true
        subject.refresh(true)
        expect(subject.auth_token).to eq :access
      end
    end

    context 'raises an exception' do

      it 'when client id and secret are missing' do
        expect { client.refresh }.to raise_exception 'Require Client Id and Client Secret to refresh tokens'
      end

      it 'when client id is missing' do
        client.secret = 1234
        expect { client.refresh }.to raise_exception 'Require Client Id and Client Secret to refresh tokens'
      end

      it 'when client secret is missing' do
        client.id = 1234
        expect { client.refresh }.to raise_exception 'Require Client Id and Client Secret to refresh tokens'
      end
    end
  end

  describe 'includes HTTPRequest' do

    subject { FuelSDK::Client.new }

    it { should respond_to(:get) }
    it { should respond_to(:post) }
    it { should respond_to(:patch) }
    it { should respond_to(:delete) }
  end
end
