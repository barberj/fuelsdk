module FuelSDK::Targeting
  attr_accessor :auth_token
  attr_accessor :endpoint

  include FuelSDK::HTTPRequest

  def refresh
    raise NotImplementedError
  end

  def endpoint
    @endpoint ||= determine_stack
  end

  protected
    def determine_stack
      refresh unless self.auth_token
      options = {'params' => {'access_token' => self.auth_token}}
      response = get("https://www.exacttargetapis.com/platform/v1/endpoints/soap", options)
      raise 'Unable to determine stack' unless response.success?
      response['url']
    end
end
