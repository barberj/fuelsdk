fuelsdk [![Gem Version](https://badge.fury.io/rb/fuelsdk.png)](http://badge.fury.io/rb/fuelsdk) [![Code Climate](https://codeclimate.com/github/barberj/fuelsdk.png)](https://codeclimate.com/github/barberj/fuelsdk) [![Build Status](https://travis-ci.org/barberj/fuelsdk.png?branch=master)](https://travis-ci.org/barberj/fuelsdk) [![Coverage Status](https://coveralls.io/repos/barberj/fuelsdk/badge.png?branch=master)](https://coveralls.io/r/barberj/fuelsdk?branch=master)
============

# Looking for owners. I don't actively use ExactTarget any more. Please email if you are interested.

ExactTarget Fuel SDK for Ruby

## Overview ##
The Fuel SDK for Ruby provides easy access to ExactTarget's Fuel API Family services, including a collection of REST APIs and a SOAP API. These APIs provide access to ExactTarget functionality via common collection types such as array/hash.

## Requirements ##
Ruby Version 1.9.3

## Getting Started ##
Add this line to your application's Gemfile:

```ruby
gem 'fuelsdk'
```

If you have not registered your application or you need to lookup your Application Key or Application Signature values, please go to App Center at [Code@: ExactTarget's Developer Community](http://code.exacttarget.com/appcenter "Code@ App Center").

## Backwards Compatibility ##
Previous versions of the Fuel SDK exposed objects with the prefix "ET_". For backwards compatibility you can still access objects this way.
Subscriber can be accessed FuelSDK::Subscriber or ET_Subscriber.

## Example Request ##

Add a require statement to reference the Fuel SDK's functionality:
> require 'fuelsdk'

Next, create an instance of the Client class:
> myClient = FuelSDK::Client.new {'client' => { 'id' => CLIENTID, 'secret' => SECRET }}

https://developer.salesforce.com/docs/atlas.en-us.mc-getting-started.meta/mc-getting-started/requestToken.htm

Note: Added new option to client initilizer 'refresh_token_url' (changes depending on ET environment) 
> myClient = FuelSDK::Client.new { 'client' => {...}, 'refresh_token_url' => 'https://auth-test.exacttargetapis.com/v1/requestToken', 'defaultwsdl' => 'https://webservice.test.exacttarget.com/etframework.wsdl' }

https://developer.salesforce.com/docs/atlas.en-us.noversion.mc-apis.meta/mc-apis/getting_started_developers_and_the_exacttarget_api.htm

Note: Added 'endpoint_service_url' accessor to Targeting to allow specifying different soap endpoint
> myClient.endpoint_service_url = 'https://webservice.test.exacttarget.com/Service.asmx' # depending on ET instance

Create an instance of the object type we want to work with:
> list = FuelSDK::List.new

Associate the Client to the object using the client property:
> list.client = myClient

Utilize one of the List methods:
> response = list.get

Print out the results for viewing
> p response

**Example Output:**

<pre>
<FuelSDK::SoapResponse:0x007fb86abcf190
 @body= {:retrieve_response_msg=> {:overall_status=>"OK", :request_id=>"XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX", :results=>..}
 @code= 200,
 @message= 'OK',
 @request_id="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
 @results=
  [{:client=>{:id=>"xxxx"},
    :partner_key=>nil,
    :created_date=>
     #<DateTime: 2013-05-30T23:02:00+00:00 ((2456443j,82920s,0n),+0s,2299161j)>,
    :id=>"xxxx",
    :object_id=>nil,
    :email_address=>"xxxx",
    :attributes=>
     [{:name=>"Full Name", :value=>"Justin Barber"},
      {:name=>"Gender", :value=>nil},
      {:name=>"Email Address", :value=>"xxx"},
      {:name=>"User Defined", :value=>"02/02/1982"}],
    :subscriber_key=>"xxxx",
    :status=>"Active",
    :email_type_preference=>"HTML",
    :"@xsi:type"=>"Subscriber"},
 @success=true>
</pre>

## Client Class ##

The Client class takes care of many of the required steps when accessing ExactTarget's API, including retrieving appropriate access tokens, handling token state for managing refresh, and determining the appropriate endpoints for API requests.  In order to leverage the advantages this class provides, use a single instance of this class for an entire session.  Do not instantiate a new Client object for each request made.

## Responses ##
All methods on Fuel SDK objects return a generic object that follows the same structure, regardless of the type of call.  This object contains a common set of properties used to display details about the request.

- success?: Boolean value that indicates if the call was successful
- code: HTTP Error Code (will always be 200 for SOAP requests)
- message: Text values containing more details in the event of an error
- results: Collection containing the details unique to the method called.
- more? - Boolean value that indicates on Get requests if more data is available.


## Samples ##
Find more sample files that illustrate using all of the available functions for ExactTarget objects exposed through the API in the samples directory.

Sample List:

 - [BounceEvent](https://github.com/ExactTarget/FuelSDK-Ruby/blob/master/samples/sample-bounceevent.rb)
 - [Campaign](https://github.com/ExactTarget/FuelSDK-Ruby/blob/master/samples/sample-campaign.rb)
 - [ClickEvent](https://github.com/ExactTarget/FuelSDK-Ruby/blob/master/samples/sample-clickevent.rb)
 - [ContentArea](https://github.com/ExactTarget/FuelSDK-Ruby/blob/master/samples/sample-contentarea.rb)
 - [DataExtension](https://github.com/ExactTarget/FuelSDK-Ruby/blob/master/samples/sample-dataextension.rb)
 - [Email](https://github.com/ExactTarget/FuelSDK-Ruby/blob/master/samples/sample-email.rb)
 - [List](https://github.com/ExactTarget/FuelSDK-Ruby/blob/master/samples/sample-list.rb)
 - [List > Subscriber](https://github.com/ExactTarget/FuelSDK-Ruby/blob/master/samples/sample-list.subscriber.rb)
 - [OpenEvent](https://github.com/ExactTarget/FuelSDK-Ruby/blob/master/samples/sample-openevent.rb)
 - [SentEvent](https://github.com/ExactTarget/FuelSDK-Ruby/blob/master/samples/sample-sentevent.rb)
 - [Subscriber](https://github.com/ExactTarget/FuelSDK-Ruby/blob/master/samples/sample-subscriber.rb)
 - [TriggeredSend](https://github.com/ExactTarget/FuelSDK-Ruby/blob/master/samples/sample-triggeredsend.rb)
 - [UnsubEvent](https://github.com/ExactTarget/FuelSDK-Ruby/blob/master/samples/sample-unsubevent.rb)






