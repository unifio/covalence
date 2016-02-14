require 'json'
require 'rest-client'
require 'base64'

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
        fail "Requested key '#{name}' not found"
      end
    end
  end

  def self.get_output(name, stack)

    @cache[stack][name] || begin
      # Create and execute HTTP request
      request = "#{URL}/v1/kv/#{stack}"

      # Configure request headers
      headers = {}
      headers['X-Consul-Token'] = ENV['CONSUL_HTTP_TOKEN'] if ENV.has_key? 'CONSUL_HTTP_TOKEN'

      begin
        response = RestClient.get request, headers
      rescue RestClient::ExceptionWithResponse => err
        fail "Unable to retrieve output '#{name}' from the '#{stack}' stack: " + err.message
      end

      # Parse JSON response
      parsed = JSON.parse(response)
      outputs = parsed.fetch("modules")[0].fetch("outputs")

      # Populate the cache for subsequent calls
      outputs.keys.each do |key|
        @cache[stack][name] = outputs.fetch(key)
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
  def self.get_state_store(name)
    "-backend-config=\"path=#{name}\" -backend=Consul"
  end
end
