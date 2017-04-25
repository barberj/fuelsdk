module FuelSDK::Targeting
  attr_accessor :auth_token
  attr_accessor :endpoint
  attr_accessor :endpoint_service_url

  include FuelSDK::HTTPRequest

  def refresh
    raise NotImplementedError
  end

  def endpoint
    @endpoint ||= determine_stack(@endpoint_service_url)
  end

  # https://developer.salesforce.com/docs/atlas.en-us.noversion.mc-apis.meta/mc-apis/getting_started_developers_and_the_exacttarget_api.htm
  # Allow different endpoint url to be used between sandbox / production ET environment
  def determine_stack(endpoint_service_url=nil)
    refresh unless self.auth_token
    options = {'params' => {'access_token' => self.auth_token}}
    response = get(endpoint_service_url || "https://www.exacttargetapis.com/platform/v1/endpoints/soap", options)
    raise 'Unable to determine stack' unless response.success?
    response['url']
  end
end
