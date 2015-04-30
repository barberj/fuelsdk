require 'coveralls'
Coveralls.wear!

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'its'
require 'fuelsdk'
require 'pry'
require 'webmock/rspec'
require "savon/mock/spec_helper"

RSpec.configure do |config|
  config.mock_with :rspec
  config.include Savon::SpecHelper

  begin
    # Use color in STDOUT
    config.color_enabled = true
  rescue
  end

  # Use the specified formatter
  config.formatter = :documentation

  config.before(:all) do
    savon.mock!
  end

  config.after(:all) do
    savon.unmock!
  end

end

shared_examples_for 'Response Object' do
  it { should respond_to(:code) }
  it { should respond_to(:message) }
  it { should respond_to(:results) }
  it { should respond_to(:request_id) }
  it { should respond_to(:body) }
  it { should respond_to(:raw) }
  it { should respond_to(:more) }
  it { should respond_to(:more?) }
  it { should respond_to(:success) }
  it { should respond_to(:success?) }
  it { should respond_to(:status) }
  it { should respond_to(:continue) }
end

# Everything will be readable so test for shared from Read behavior
shared_examples_for 'Soap Read Object' do
  # begin backwards compat
  it { should respond_to :props= }
  it { should respond_to :authStub= }
  # end
  it { should respond_to :id }
  it { should respond_to :properties }
  it { should respond_to :client }
  it { should respond_to :filter }
  it { should respond_to :info }
  it { should respond_to :get }
end

shared_examples_for 'Soap CUD Object' do
  it { should respond_to :post }
  it { should respond_to :patch }
  it { should respond_to :delete }
end

shared_examples_for 'Soap Object' do
  it_behaves_like 'Soap Read Object'
  it_behaves_like 'Soap CUD Object'
end

shared_examples_for 'Soap Read Only Object' do
  it_behaves_like 'Soap Read Object'
  it { should_not respond_to :post }
  it { should_not respond_to :patch }
  it { should_not respond_to :delete }
end

