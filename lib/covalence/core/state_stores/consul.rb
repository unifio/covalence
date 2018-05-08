require 'json'
require 'rest-client'
require 'base64'

require_relative '../../helpers/shell_interpolation'

module Covalence
  module Consul

    ##### Consul ennvironment variables #####
    #
    # CONSUL_HTTP_ADDR - DNS name and port of your Consul endpoint specified in the format dnsname:port.
    #                    Defaults to the local agent HTTP listener.
    # CONSUL_HTTP_SSL  - Specifies what protocol to use when talking to the given address, either http or https.
    # CONSUL_HTTP_AUTH - HTTP Basic Authentication credentials to be used when communicating with Consul,
    #                    in the format of either user or user:pass.
    # CONSUL_HTTP_TOKEN - HTTP authentication token.

    URL = ENV['CONSUL_HTTP_ADDR'] || 'localhost:8500'

    def self.reset_cache()
      @cache = Hash.new{|h,k| h[k] = Hash.new}
    end

    reset_cache

    def self.get_key(name)

      @cache['root'][name] ||= begin
        # Create and execute HTTP request
        request = "#{URL}/v1/kv/#{name}"

        # Configure request headers
        headers = {}
        headers['X-Consul-Token'] = ENV['CONSUL_HTTP_TOKEN'] if ENV.has_key? 'CONSUL_HTTP_TOKEN'

        begin
          response = RestClient.get request, headers
        rescue RestClient::ExceptionWithResponse => err
          fail "Unable to retrieve key '#{name}': " + err.message
        end

        # Parse JSON response
        begin
          parsed = JSON.parse(response)
          encoded = parsed.first['Value']
        rescue JSON::ParserError => err
          fail "No results or unable to parse response: " + err.message
        end

        # Return decoded value
        if encoded != nil
          Base64.decode64(encoded)
        else
          # TODO: not sure if this is the right failure to raise
          fail "Requested key '#{name}' not found"
        end
      end
    end

    def self.get_output(name, stack)

      @cache[stack][name] || begin
        # Retrieve stack state
        value = self.get_key(stack)

        # Parse JSON
        parsed = JSON.parse(value)
        outputs = parsed.fetch("modules")[0].fetch("outputs")

        # Populate the cache for subsequent calls
        outputs.keys.each do |key|
          @cache[stack][key] = outputs.fetch(key)
        end

        # Check outputs for requested key and return
        if outputs.has_key?(name)
          @cache[stack][name]
        else
          fail("Requested output '#{name}' not found")
        end
      end
    end

    # Return configuration for remote state store.
    def self.get_state_store(params)
      raise "State store parameters must be a Hash" unless params.is_a?(Hash)
      required_params = [
        'access_token',
        'name'
      ]
      required_params.each do |param|
        raise "Missing '#{param}' store parameter" unless params.has_key?(param)
      end

      config = <<-CONF
terraform {
  backend "consul" {
    path = "#{params['name']}"
CONF

      params.delete('name')
      params.each do |k,v|
        v = Covalence::Helpers::ShellInterpolation.parse_shell(v) if v.include?("$(")
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
      when type == 'key'
        raise "Missing 'key' lookup parameter" unless params.has_key? 'key'
        self.get_key(params['key'])
      when type == 'state'
        required_params = [
          'key',
          'stack'
        ]
        required_params.each do |param|
          raise "Missing '#{param}' lookup parameter" unless params.has_key?(param)
        end
        self.get_output(params['key'],params['stack'])
      else
        raise "Consul module does not support the '#{type}' lookup type"
      end
    end
  end
end
