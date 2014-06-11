module FuelSDK
  class Response
    # not doing accessor so user, can't update these values from response.
    # You will see in the code some of these
    # items are being updated via back doors and such.
    attr_reader :code, :message, :results, :request_id, :body, :raw, :decoded_jwt

    # some defaults
    def success
      @success ||= false
    end
    alias :success? :success
    alias :status :success # backward compatibility

    def more
      @more ||= false
    end
    alias :more? :more

    def initialize raw=nil, client=nil
      @client = client # keep connection with client in case we request more
      @results = []
      @raw = raw
      unpack raw if raw
    rescue => ex # all else fails return raw
      puts ex.message
      raw
    end

    def continue
      raise NotImplementedError
    end

    private
      def unpack raw
        raise NotImplementedError
      end
  end

  class Client
    attr_accessor :debug, :auth_token, :internal_token, :refresh_token,
      :id, :secret, :signature

    include FuelSDK::Soap
    include FuelSDK::Rest

    def cache
      @cache ||= {
        :retrievable => {},
        :editable => {}
      }
    end

    def jwt= encoded_jwt
      raise 'Require app signature to decode JWT' unless self.signature
      self.decoded_jwt=JWT.decode(encoded_jwt, self.signature, true)
    end

    def decoded_jwt= decoded_jwt
      @decoded_jwt = decoded_jwt
      self.auth_token = decoded_jwt['request']['user']['oauthToken']
      self.internal_token = decoded_jwt['request']['user']['internalOauthToken']
      self.refresh_token = decoded_jwt['request']['user']['refreshToken']
      #@authTokenExpiration = Time.new + decoded_jwt['request']['user']['expiresIn']
    end

    def initialize(params={}, debug=false)
      self.debug = debug
      client_config = params['client']
      if client_config
        self.id = client_config["id"]
        self.secret = client_config["secret"]
        self.signature = client_config["signature"]
      end

      self.jwt = params['jwt'] if params['jwt']
      self.refresh_token = params['refresh_token'] if params['refresh_token']

      self.wsdl = params["defaultwsdl"] if params["defaultwsdl"]
    end

    def request_token_data
      raise 'Require Client Id and Client Secret to refresh tokens' unless (id && secret)
      {
        'clientId' => id,
        'clientSecret' => secret,
        'accessType' => 'offline'
      }.tap do |h|
        h['refreshToken'] = refresh_token if refresh_token
      end
    end

    def request_token_options data
      {
        'data' => data,
        'content_type' => 'application/json',
        'params' => {'legacy' => 1}
      }
    end

    def clear_client!
      @soap_client = nil
    end

    def refresh force=false
      if (self.auth_token.nil? || force)
        clear_client!
        options =  request_token_options(request_token_data)
        response = post("https://auth.exacttargetapis.com/v1/requestToken", options)
        raise "Unable to refresh token: #{response['message']}" unless response.has_key?('accessToken')

        self.auth_token = response['accessToken']
        self.internal_token = response['legacyToken']
        self.refresh_token = response['refreshToken'] if response.has_key?("refreshToken")
      end
    end

    def refresh!
      refresh true
    end

    def AddSubscriberToList(email, ids, subscriber_key = nil)
      s = FuelSDK::Subscriber.new
      s.client = self
      lists = ids.collect{|id| {'ID' => id}}
      s.properties = {"EmailAddress" => email, "Lists" => lists}
      s.properties['SubscriberKey'] = subscriber_key if subscriber_key

      # Try to add the subscriber
      if(rsp = s.post and rsp.results.first[:error_code] == '12014')
        # subscriber already exists we need to update.
        rsp = s.patch
      end
      rsp
    end

    def CreateDataExtensions(definitions)
      de = FuelSDK::DataExtension.new
      de.client = self
      de.properties = definitions
      de.post
    end
  end
end
