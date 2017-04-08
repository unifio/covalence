require 'json'
require 'aws-sdk'

module Covalence
  module S3

    ##### AWS ennvironment variables #####
    #
    # AWS_ACCESS_KEY_ID – AWS access key.
    # AWS_SECRET_ACCESS_KEY – AWS secret key. Access and secret key variables override
    #                         credentials stored in credential and config files.
    # AWS_REGION – AWS region. This variable overrides the default region of the in-use
    #              profile, if set.

    REGION = ENV['AWS_REGION']

    class Client
      def initialize(region: REGION)
        @s3 = Aws::S3::Client.new(region: region)
        self.reset_cache
      end

      def reset_cache
        @cache = Hash.new{|h,k| h[k] = Hash.new}
      end

      def get_cache
        @cache.to_s
      end

      def get_doc(bucket, document)
        @cache[bucket][document] ||= begin
          @s3.get_object(bucket: bucket, key: document).body.read
        rescue Aws::S3::Errors::ServiceError => err
          fail "Unable to retrieve document '#{document}' from bucket '#{bucket}': " + err.message
        end
      end

      def get_key(bucket, document, name)
        doc = self.get_doc(bucket, document)

        # Parse JSON response
        begin
          parsed = JSON.parse(doc)
        rescue JSON::ParserError => err
          fail "No results or unable to parse document '#{document}': " + err.message
        end

        # Determine whether the document is a Terraform state file
        tf_state = true if parsed.has_key?('modules')

        # Return ID for the key specified
        if tf_state
          outputs = parsed.fetch('modules')[0].fetch('outputs')
          return outputs.fetch(name)
        end
        return parsed.fetch(name) if parsed.has_key?(name)
        fail "Requested key '#{name}' not found"
      end
    end

    # Return configuration for remote state store.
    def self.get_state_store(params)
      raise "State store parameters must be a Hash" unless params.is_a?(Hash)
      required_params = [
        'bucket',
        'name'
      ]
      required_params.each do |param|
        raise "Missing '#{param}' store parameter" unless params.has_key?(param)
      end

      config = <<-CONF
terraform {
  backend "s3" {
    key = "#{params['name']}/terraform.tfstate"
CONF

      params.delete('name')
      params.each do |k,v|
        config += "    #{k} = \"#{v}\"\n"
      end

      config += "  }\n}\n"

      return config
    end

    # Return module capabilities
    # TODO: maybe a state_store mixin later
    #def self.has_key_read?
      #return true
    #end

    #def self.has_key_write?
      #return false
    #end

    #def self.has_state_read?
      #return true
    #end

    def self.has_state_store?
      return true
    end

    # Key lookups
    def self.lookup(type, params)
      raise "Lookup parameters must be a Hash" unless params.is_a?(Hash)

      case
      when type == 'key' || type == 'state'
        required_params = [
          'bucket',
          'document',
          'key'
        ]
        required_params.each do |param|
          raise "Missing '#{param}' lookup parameter" unless params.has_key?(param)
        end
        raise "Missing 'key' lookup parameter" unless params.has_key? 'key'
        client = S3::Client.new(region: REGION)
        client.get_key(params['bucket'],params['document'],params['key'])
      end
    end
  end
end
