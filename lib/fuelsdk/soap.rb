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
       rsp = unpack @client.soap_client.call(:retrieve, :message => {'RetrieveRequest' => {'ContinueRequest' => request_id}})
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
        rslts = Array.wrap(rslts)
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
        _exts = Array.wrap(_exts) # if they have only one extended property we need to wrap it in array to iterate
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
        'oAuth' => {
          'oAuthToken' => internal_token,
          '@xmlns' => 'http://exacttarget.com'
         }
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

    def describe_object_type_message object_type
      {
        'DescribeRequests' => {
          'ObjectDefinitionRequest' => {
            'ObjectType' => object_type
          }
        }
      }
    end

    def describe_dataextension_message dataextension
      {
        'Property' => "DataExtension.CustomerKey",
        'SimpleOperator' => 'equals',
        'Value' => dataextension
      }
    end

    def describe_data_extension dataextension
      soap_get('DataExtensionField',
        'Name',
        describe_dataextension_message(dataextension)
      )
    end

    def soap_describe object_type
      soap_request :describe, describe_object_type_message(object_type)
    end

    def describe object_type
      rsp = soap_describe(object_type)
      unless rsp.success?
        rsp = describe_data_extension object_type
      end
      rsp
    end

    def get_all_object_properties object_type
      rsp = soap_describe object_type
      raise DescribeError.new(rsp, "Unable to get #{object_type}") unless rsp.success?
      rsp
    end

    def get_dataextension_properties dataextension
      describe_dataextension(dataextension)
        .results.collect{|f| f[:name]}
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
      elsif is_a_dataextension? object_type
        []
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
      elsif is_a_dataextension? object_type
        []
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
      filter['@xsi:type'] = 'tns:SimpleFilterPart'
      {
        'Filter' => filter
      }
    end

    def add_complex_filter_part filter
      raise 'Missing SimpleFilterParts' if !filter['LeftOperand'] || !filter['RightOperand']
      filter['LeftOperand']['@xsi:type']  = 'tns:SimpleFilterPart'
      filter['RightOperand']['@xsi:type'] = 'tns:SimpleFilterPart'
      filter['@xsi:type'] = 'tns:ComplexFilterPart'

      {
        'Filter' => filter
      }
    end

    def normalize_customer_key filter, object_type
      filter.tap do |f|
        if is_a_dataextension? object_type
          if filter['Property'] == 'CustomerKey'
            f['Property'] = 'DataExtension.CustomerKey'
          end
        end
      end
    end

    def normalize_filter filter, object_type=''
      if filter and filter.kind_of? Hash
        normalize_customer_key filter, object_type
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

    def soap_upsert object_type, properties
      options = {'SaveOptions' => [{'SaveOption' => {'PropertyName'=> "*", 'SaveAction' => "UpdateAdd"}}]}
      soap_cud :update, object_type, properties, options
    end

    def soap_put object_type, properties
      soap_cud :update, object_type, properties
    end
    alias_method :soap_patch, :soap_put

    def soap_delete object_type, properties
      soap_cud :delete, object_type, properties
    end

    def create_action_message message_type, object_type, properties, action
      properties = Array.wrap(properties)
      properties.each do |property|
        property['@xsi:type'] = "tns:#{object_type}"
      end

      {
        'Action' => action,
        message_type => {
          message_type.singularize => properties,
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
      object_properties.each do |property|
        property['@xsi:type'] = "tns:#{object_type}"
      end

      {
        'Objects' => object_properties,
      }
    end

    def format_dataextension_cud_properties properties
      Array.wrap(properties).each do |p|
        formated_attrs = []
        p.each do |k, v|
          unless k == 'CustomerKey'
            p.delete k
            attrs = FuelSDK.format_name_value_pairs k => v
            formated_attrs.concat attrs
          end
        end
        unless formated_attrs.blank?
          p['Properties'] ||= {}
          (p['Properties']['Property'] ||= []).concat formated_attrs
        end
      end
    end

    def is_a_dataextension? object_type
      object_type.start_with? 'DataExtension'
    end

    def format_object_cud_properties object_type, properties
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

    def normalize_properties_for_cud object_type, properties
      properties = Array.wrap(properties)
      raise 'Object properties must be a Hash' unless properties.first.kind_of? Hash

      if is_a_dataextension? object_type
        format_dataextension_cud_properties properties
      else
        format_object_cud_properties object_type, properties
      end

    end

    private

      def soap_cud action, object_type, properties, options = {}
        properties = normalize_properties_for_cud object_type, properties
        message = create_objects_message object_type, properties
        message['Options'] = options
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
