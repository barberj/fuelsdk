require 'spec_helper'

describe FuelSDK::Targeting do

  subject { Class.new.new.extend(FuelSDK::Targeting) }

  it { should respond_to(:endpoint) }
  it { should_not respond_to(:endpoint=) }
  it { should respond_to(:determine_stack) }
  it { should respond_to(:get) }
  it { should respond_to(:post) }
  it { should respond_to(:patch) }
  it { should respond_to(:delete) }
  it { should respond_to(:access_token) }

  let(:response) {
    rsp = double(FuelSDK::HTTPResponse)
    rsp.stub(:success?).and_return(true)
    rsp.stub(:[]).with('url').and_return('S#.authentication.target')
    rsp
  }

  let(:client) {
    Class.new.new.extend(FuelSDK::Targeting)
  }

  describe '#determine_stack' do
    it 'when successful returns endpoint' do
      client.stub(:get)
        .with('https://www.exacttargetapis.com/platform/v1/endpoints/soap', {'params'=>{'access_token'=>'open_sesame'}})
        .and_return(response)
      client.should_receive(:access_token).and_return('open_sesame')
      expect(client.send(:determine_stack)).to eq 'S#.authentication.target'
    end

    it 'raises error on unsuccessful responses' do
      client.stub(:get).and_return{
        rsp = double(FuelSDK::HTTPResponse)
        rsp.stub(:success?).and_return(false)
        rsp
      }
      expect{ client.send(:determine_stack) }.to raise_error 'Unable to determine stack'
    end
  end

  describe '#endpoint' do
    it 'calls determine_stack to find target' do
      client.should_receive(:determine_stack).and_return('S#.authentication.target')
      expect(client.endpoint).to eq 'S#.authentication.target'
    end
  end
end
