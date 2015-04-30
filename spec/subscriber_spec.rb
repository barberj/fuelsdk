require 'spec_helper'

describe 'Subscriber' do

  let(:base) { 'spec/fixtures/webmock/subscriber' }

  let(:auth) do
    {
      'client' => {
        'id'     => 'kevy_id',
        'secret' => 'kevy_secret'
      }
    }
  end

  let!(:stub_wsdl_request) do
    stub_request(:get, "https://webservice.exacttarget.com/etframework.wsdl").
      to_return(File.new("spec/fixtures/webmock/client/wsdl.txt"))
  end

  let!(:stub_determine_endpoint) do
    stub_request(:get, "https://www.exacttargetapis.com/platform/v1/endpoints/soap").
      with(:query => { 'access_token' => 'access' }).
      to_return(File.new("spec/fixtures/webmock/client/endpoint.txt"))
  end

  let!(:stub_refresh_tokens) do
    stub_request(:post, "https://auth.exacttargetapis.com/v1/requestToken").
      with(:query => { 'legacy' => 1 },
        :body      => {
          'clientId'     => 'kevy_id',
          'clientSecret' => 'kevy_secret',
          'accessType'   => 'offline',
        }).
      to_return(File.new("spec/fixtures/webmock/client/tokens.txt"))
  end

  let(:client) { FuelSDK::Client.new(auth) }

  let(:stub_describes) do
    savon.expects(:describe).
      with(:message => {
        'DescribeRequests' => {
          'ObjectDefinitionRequest' => {
            'ObjectType' => 'Subscriber'
          }
        }
      }).
      returns(File.read("#{base}/description.xml"))
  end

  it 'describes' do
    stub_describes

    rsp = client.describe('Subscriber')
    expect(rsp.retrievable).to include(
      'EmailAddress'
    )
    expect(rsp.editable).to include(
      'Gender'
    )
    expect(rsp.editable).not_to include(
      'ModifiedDate'
    )
  end
  it 'reads specified properties' do
    savon.expects(:retrieve).
      with(:message => {
        'RetrieveRequest' => {
          'ObjectType' => 'Subscriber',
          'Properties' => [
            "ID",
            "EmailAddress",
          ]
        }
      }).
      returns(File.read("#{base}/subscribers.xml"))

    rsp = client.soap_get('Subscriber', ['ID', 'EmailAddress'])

    expect(rsp.success).to be true
    expect(rsp.results.count).to eq 2

    expect(rsp.results.first[:id]).to eq '16234076'
    expect(rsp.results.first[:attributes]).to include(
      {:name=>"Available Weekends", :value=>"False"}
    )

    expect(rsp.results.last[:id]).to eq '16234077'
    expect(rsp.results.last[:attributes]).to include(
      {:name=>"Available Weekends", :value=>"True"}
    )
  end
  it 'reads all properties' do
    stub_describes
    savon.expects(:retrieve).
      with(:message => {
        'RetrieveRequest' => {
          'ObjectType' => 'Subscriber',
          'Properties' => [
            "ID",
            "PartnerKey",
            "CreatedDate",
            "Client.ID",
            "Client.PartnerClientKey",
            "EmailAddress",
            "SubscriberKey",
            "UnsubscribedDate",
            "Status",
            "EmailTypePreference",
          ]
        }
      }).
      returns(File.read("#{base}/subscribers_with_all_properties.xml"))

    rsp = client.soap_get('Subscriber')

    expect(rsp.success).to be true
    expect(rsp.results.count).to eq 2

    expect(rsp.results.first[:id]).to eq '16234076'
    expect(rsp.results.first[:status]).to eq 'Active'
    expect(rsp.results.first[:attributes]).to include(
      {:name=>"Available Weekends", :value=>"False"}
    )

    expect(rsp.results.last[:id]).to eq '16234077'
    expect(rsp.results.last[:status]).to eq 'Unsubscribed'
    expect(rsp.results.last[:attributes]).to include(
      {:name=>"Available Weekends", :value=>"True"}
    )
  end
  it 'reads with a simple filter' do
    stub_describes
    savon.expects(:retrieve).
      with(:message => {
        'RetrieveRequest' => {
          'ObjectType' => 'Subscriber',
          'Properties' => [
            "ID",
            "PartnerKey",
            "CreatedDate",
            "Client.ID",
            "Client.PartnerClientKey",
            "EmailAddress",
            "SubscriberKey",
            "UnsubscribedDate",
            "Status",
            "EmailTypePreference",
          ],
          'Filter' => {
            'Property'       => 'ID',
            'SimpleOperator' => 'equals',
            'Value'          => '16234076',
            '@xsi:type'      => 'tns:SimpleFilterPart'
          }
        }
      }).
      returns(File.read("#{base}/subscriber.xml"))

    rsp = client.soap_get('Subscriber', nil,
      'Property'       => 'ID',
      'SimpleOperator' => 'equals',
      'Value'          => '16234076'
    )

    expect(rsp.success).to be true
    expect(rsp.results.count).to eq 1

    expect(rsp.results.first[:id]).to eq '16234076'
    expect(rsp.results.first[:status]).to eq 'Active'
    expect(rsp.results.first[:attributes]).to include(
      {:name=>"Available Weekends", :value=>"False"}
    )
  end
  it 'reads with a complex filter' do
    stub_describes
    savon.expects(:retrieve).
      with(:message => {
        'RetrieveRequest' => {
          'ObjectType' => 'Subscriber',
          'Properties' => [
            "ID",
            "PartnerKey",
            "CreatedDate",
            "Client.ID",
            "Client.PartnerClientKey",
            "EmailAddress",
            "SubscriberKey",
            "UnsubscribedDate",
            "Status",
            "EmailTypePreference",
          ],
          'Filter' => {
            'LeftOperand'     => {
              'Property'       => 'ID',
              'SimpleOperator' => 'equals',
              'Value'          => '16234076',
              '@xsi:type'      => 'tns:SimpleFilterPart'
            },
            'RightOperand'    => {
              'Property'       => 'ID',
              'SimpleOperator' => 'equals',
              'Value'          => '16234077',
              '@xsi:type'      => 'tns:SimpleFilterPart'
            },
            'LogicalOperator' => 'OR',
            '@xsi:type'       => 'tns:ComplexFilterPart'
          }
        }
      }).
      returns(File.read("#{base}/subscriber.xml"))

    rsp = client.soap_get('Subscriber', nil, {
      'LeftOperand' => {
        'Property'       => 'ID',
        'SimpleOperator' => 'equals',
        'Value'          => '16234076'
      },
      'RightOperand' => {
        'Property'       => 'ID',
        'SimpleOperator' => 'equals',
        'Value'          => '16234077'
      },
      'LogicalOperator' => 'OR'
    })

    expect(rsp.success).to be true
    expect(rsp.results.count).to eq 1

    expect(rsp.results.first[:id]).to eq '16234076'
    expect(rsp.results.first[:status]).to eq 'Active'
    expect(rsp.results.first[:attributes]).to include(
      {:name=>"Available Weekends", :value=>"False"}
    )
  end
  it 'creates' do
    stub_describes
    savon.expects(:create).
      with(:message => {
        'Objects' => [{
          'EmailAddress'       => 'fuelsdk@exacttarget.com',
          'Attributes' => [{
            'Name'  => 'Gender',
            'Value' => 'M'
          },{
            'Name'  => 'Available Weekends',
            'Value' => true
          }],
          '@xsi:type'          => 'tns:Subscriber'
        }]}).
      returns(File.read("#{base}/created.xml"))

    rsp = client.soap_post('Subscriber',
      'EmailAddress'       => 'fuelsdk@exacttarget.com',
      'Gender'             => 'M',
      'Available Weekends' => true
    )
    expect(rsp.success).to be true
    expect(rsp.results.first[:new_id]).to eq '37576181'
  end
  it 'updates' do
    stub_describes
    savon.expects(:update).
      with(:message => {
        'Objects' => [{
          'EmailAddress'       => 'fuelsdk@exacttarget.com',
          'Attributes' => [{
            'Name'  => 'Gender',
            'Value' => 'M'
          },{
            'Name'  => 'Available Weekends',
            'Value' => true
          }],
          '@xsi:type'          => 'tns:Subscriber'
        }]}).
      returns(File.read("#{base}/updated.xml"))

    rsp = client.soap_put('Subscriber',
      'EmailAddress'       => 'fuelsdk@exacttarget.com',
      'Gender'             => 'M',
      'Available Weekends' => true
    )
    expect(rsp.success).to be true
    expect(rsp.results.first).to include(
      :status_code    => "OK",
      :status_message => "Updated Subscriber."
    )
    expect(rsp.results.first[:object][:id]).to eq '16234076'
    expect(rsp.results.first[:object][:attributes]).to include(
      {:name => "Available Weekends", :value => true}
    )
  end
  it 'deletes' do
    stub_describes
    savon.expects(:delete).
      with(:message => {
        'Objects' => [{
          'EmailAddress'       => 'fuelsdk@exacttarget.com',
          'Attributes' => [{
            'Name'  => 'Gender',
            'Value' => 'M'
          },{
            'Name'  => 'Available Weekends',
            'Value' => true
          }],
          '@xsi:type'          => 'tns:Subscriber'
        }]}).
      returns(File.read("#{base}/deleted.xml"))

    rsp = client.soap_delete('Subscriber',
      'EmailAddress'       => 'fuelsdk@exacttarget.com',
      'Gender'             => 'M',
      'Available Weekends' => true
    )
    expect(rsp.success).to be true
    expect(rsp.results.first).to include(
      :status_code    => "OK",
      :status_message => "Subscriber deleted"
    )
  end
end
