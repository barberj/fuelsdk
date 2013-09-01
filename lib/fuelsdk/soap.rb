require 'savon'
module FuelSDK

  class DescribeError < StandardError
    attr_reader :response
    def initialize response=nil, message=nil
      response.instance_variable_set(:@message, message) # back door update
      @response = response
      super message
    end
  end

  class SoapResponse < FuelSDK::Response

    def continue
      rsp = nil
      if more?
       rsp = unpack @client.soap_client.call(:retrieve, :message => {'ContinueRequest' => request_id})
      else
        puts 'No more data'
      end

      rsp
    end

    private
      def unpack_body raw
        @body = raw.body
        @request_id = raw.body[raw.body.keys.first][:request_id]
        unpack_msg raw
      rescue
        @message = raw.http.body
        @body = raw.http.body unless @body
      end

      def unpack raw
        @code = raw.http.code
        unpack_body raw
        @success = @message == 'OK'
        @results += (unpack_rslts raw)
      end

      def unpack_msg raw
        @message = raw.soap_fault? ? raw.body[:fault][:faultstring] : raw.body[raw.body.keys.first][:overall_status]
      end

      def unpack_rslts raw
        @more = (raw.body[raw.body.keys.first][:overall_status] == 'MoreDataAvailable')
        rslts = raw.body[raw.body.keys.first][:results] || []
        rslts = [rslts] unless rslts.kind_of? Array
        rslts
      rescue
        []
      end
  end

  class DescribeResponse < SoapResponse
    attr_reader :properties, :retrievable, :updatable, :required, :extended, :viewable, :editable
    private

      def unpack_rslts raw
        @retrievable, @updatable, @required, @properties, @extended, @viewable, @editable = [], [], [], [], [], [], [], []
        definition = raw.body[raw.body.keys.first][:object_definition]
        _props = definition[:properties]
        _props.each do  |p|
          @retrievable << p[:name] if p[:is_retrievable] and (p[:name] != 'DataRetentionPeriod')
          @updatable << p[:name] if p[:is_updatable]
          @required << p[:name] if p[:is_required]
          @properties << p[:name]
        end
        # ugly, but a necessary evil
        _exts = definition[:extended_properties].nil? ? {} : definition[:extended_properties] # if they have no extended properties nil is returned
        _exts = _exts[:extended_property] || [] # if no properties nil and we need an array to iterate
        _exts = [_exts] unless _exts.kind_of? Array # if they have only one extended property we need to wrap it in array to iterate
        _exts.each do  |p|
          @viewable << p[:name] if p[:is_viewable]
          @editable << p[:name] if p[:is_editable]
          @extended << p[:name]
        end
        @success = true # overall_status is missing from definition response, so need to set here manually
        _props + _exts
      rescue
        @message = "Unable to describe #{raw.locals[:message]['DescribeRequests']['ObjectDefinitionRequest']['ObjectType']}"
        @success = false
        []
      end
  end

  module Soap
    attr_accessor :wsdl, :debug, :internal_token

    include FuelSDK::Targeting

    def header
      raise 'Require legacy token for soap header' unless internal_token
      {
        'oAuth' => {'oAuthToken' => internal_token},
        :attributes! => { 'oAuth' => { 'xmlns' => 'http://exacttarget.com' }}
      }
    end

    def debug
      @debug ||= false
    end

    def wsdl
      @wsdl ||= 'https://webservice.exacttarget.com/etframework.wsdl'
    end

    def soap_client
      self.refresh unless internal_token
      @soap_client ||= Savon.client(
        soap_header: header,
        wsdl: wsdl,
        endpoint: endpoint,
        wsse_auth: ["*", "*"],
        raise_errors: false,
        log: debug,
        open_timeout:180,
        read_timeout: 180
      )
    end

    def soap_describe object_type
      message = {
        'DescribeRequests' => {
          'ObjectDefinitionRequest' => {
            'ObjectType' => object_type
          }
        }
      }

      soap_request :describe, message
    end

    def get_all_object_properties object_type
      rsp = soap_describe object_type
      raise DescribeError.new(rsp, "Unable to get #{object_type}") unless rsp.success?
      rsp
    end

    def cache_properties action, object_type, properties
      raise 'Properties should be in cache as a list' unless properties.kind_of? Array
      cache[action][object_type] = properties
    end

    def cached_properties? action, object_type
      cache[action][object_type] rescue nil
    end

    def retrievable_properties_cached? object_type
      cached_properties? :retrievable, object_type
    end

    def cache_retrievable object_type, properties
      cache_properties :retrievable, object_type, properties
    end

    def get_retrievable_properties object_type
      if props=retrievable_properties_cached?(object_type)
        props
      else
        cache_retrievable object_type, get_all_object_properties(object_type).retrievable
      end
    end

    def editable_properties_cached? object_type
      cached_properties? :editable, object_type
    end

    def cache_editable object_type, properties
      cache_properties :editable, object_type, properties
    end

    def get_editable_properties object_type
      if props=editable_properties_cached?(object_type)
        props
      else
        cache_editable object_type, get_all_object_properties(object_type).editable
      end
    end

    def normalize_properties_for_retrieve object_type, properties
      if properties.nil? or properties.blank?
        get_retrievable_properties object_type
      elsif properties.kind_of? Hash
        properties.keys
      elsif properties.kind_of? String
        [properties]
      elsif properties.kind_of? Symbol
        [properties.to_s]
      else
        properties
      end
    end

    def add_simple_filter_part filter
      {
        'Filter' => filter,
        :attributes! => { 'Filter' => { 'xsi:type' => 'tns:SimpleFilterPart' }}
      }
    end

    def add_complex_filter_part filter
      filter[:attributes!] = {
        'LeftOperand' => { 'xsi:type' => 'tns:SimpleFilterPart' },
        'RightOperand' => { 'xsi:type' => 'tns:SimpleFilterPart' }
      }

      {
        'Filter' => filter,
        :attributes! => { 'Filter' => { 'xsi:type' => 'tns:ComplexFilterPart' }}
      }
    end

    def normalize_filter filter
      if filter and filter.kind_of? Hash
        if filter.has_key?('LogicalOperator')
          add_complex_filter_part filter
        else
          add_simple_filter_part filter
        end
      else
        {}
      end
    end

    def create_object_type_message object_type, properties, filter
      {'ObjectType' => object_type, 'Properties' => properties}.merge filter
    end

    def soap_get object_type, properties=nil, filter=nil

      properties = normalize_properties_for_retrieve object_type, properties
      filter = normalize_filter filter
      message = create_object_type_message(object_type,  properties, filter)

      soap_request :retrieve, 'RetrieveRequest' => message

    rescue DescribeError => err
      return err.response
    end

    def soap_post object_type, properties
      soap_cud :create, object_type, properties
    end

    def soap_patch object_type, properties
      soap_cud :update, object_type, properties
    end

    def soap_delete object_type, properties
      soap_cud :delete, object_type, properties
    end

    def create_action_message message_type, object_type, properties, action
      properties = [properties] unless properties.kind_of? Array
      {
        'Action' => action,
        message_type => {
          message_type.singularize => properties,
          :attributes! => {
            message_type.singularize => { 'xsi:type' => ('tns:' + object_type) }
          }
        }
      }
    end

    def soap_perform object_type, properties, action
      message = create_action_message 'Definitions', object_type, properties, action
      soap_request :perform, message
    end

    def soap_configure object_type, properties, action
      message = create_action_message 'Configurations', object_type, properties, action
      soap_request :configure, message
    end

    def create_objects_message object_type, object_properties
      raise 'Object properties must be a List' unless object_properties.kind_of? Array
      raise 'Object properties must be a List of Hashes' unless object_properties.first.kind_of? Hash

      {
        'Objects' => object_properties,
        :attributes! => {'Objects' => { 'xsi:type' => ('tns:' + object_type) }}
      }
    end

    def normalize_properties_for_cud object_type, properties
      properties = [properties] unless properties.kind_of? Array
      raise 'Object properties must be a Hash' unless properties.first.kind_of? Hash

      # get a list of attributes so we can seperate
      # them from standard object properties
      type_attrs = get_editable_properties object_type

      properties.each do |p|
        formated_attrs = []
        p.each do |k, v|
          if type_attrs.include? k
            p.delete k
            attrs = FuelSDK.format_name_value_pairs k => v
            formated_attrs.concat attrs
          end
        end
        (p['Attributes'] ||= []).concat formated_attrs unless formated_attrs.blank?
      end
    end

    private

      def soap_cud action, object_type, properties
        properties = normalize_properties_for_cud object_type, properties
        message = create_objects_message object_type, properties
        soap_request action, message
      end

      def soap_request action, message
        response = action.eql?(:describe) ? DescribeResponse : SoapResponse
        retried = false
        begin
          rsp = soap_client.call(action, :message => message)
        rescue
          raise if retried
          retried = true
          retry
        end
        response.new rsp, self
      rescue
        raise if rsp.nil?
        response.new rsp, self
      end
  end
end
