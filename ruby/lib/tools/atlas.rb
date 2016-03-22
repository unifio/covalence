require 'json'
require 'rest-client'

module Atlas
  AtlasTokenMissing = Class.new(StandardError)

  # Default base URL for Atlas.
  URL = "https://atlas.hashicorp.com"

  def self.reset_cache()
    @cache = Hash.new{|h,k| h[k] = Hash.new{|h,k| h[k] = Hash.new{|h,k| h[k] = Hash.new}}}
  end

  reset_cache

  def self.get_artifact(slug, version, key, metadata: {})
    ensure_atlas_token_set

    @cache[slug][version][key][metadata] ||= begin
      # Create and execute HTTP request
      request = "#{URL}/api/v1/artifacts/#{slug}/search"

      params = {}
      params[:version] = version
      if !metadata.empty?
        i = 1
        metadata.map do |k,v|
          params["metadata.#{i}.key"] = k
          params["metadata.#{i}.value"] = v
          i += 1
        end
      end

      headers = {:'X-Atlas-Token' => ENV['ATLAS_TOKEN']}
      headers = headers.merge({:params => params})

      begin
        response = RestClient.get request, headers
      rescue RestClient::ExceptionWithResponse => err
        fail "Unable to retrieve ID for artifact '#{slug}': " + err.message
      end

      # Parse JSON response
      parsed = JSON.parse(response)
      latest = parsed["versions"].select {|version| version['metadata'].keys.include? "#{key}" }.first

      # Return ID for the region specified
      if latest != nil
        latest["metadata"]["#{key}"]
      else
        fail "Requested key '#{key}' not found"
      end
    end
  end

  def self.get_output(name, stack)
    ensure_atlas_token_set

    @cache[stack][name][0][0] || begin
      # Create and execute HTTP request
      request = "#{URL}/api/v1/terraform/state/#{stack}"
      headers = {:'X-Atlas-Token' => ENV['ATLAS_TOKEN']}

      begin
        response = RestClient.get request, headers
      rescue RestClient::ExceptionWithResponse => err
        fail "Unable to retrieve output '#{name}' from stack '#{stack}': " + err.message
      end

      # Parse JSON response
      parsed = JSON.parse(response)
      outputs = parsed.fetch("modules")[0].fetch("outputs")

      # Populate the cache for subsequent calls
      outputs.keys.each do |key|
        @cache[stack][key][0][0] = outputs.fetch(key)
      end

      # Check outputs for requested key and return
      if outputs.has_key?(name)
        @cache[stack][name][0][0]
      else
        fail("Requested output '#{name}' not found")
      end
    end
  end

  def self.get_state_store(params)
    raise "State store parameters must be a Hash" unless params.is_a?(Hash)
    raise "Missing 'name' store parameter" unless params.has_key? 'name'

    "-backend-config=\"name=#{params['name']}\" -backend=Atlas"
  end

  def self.ensure_atlas_token_set
    raise AtlasTokenMissing.new("Missing ATLAS_TOKEN environment variable") unless ENV.key? 'ATLAS_TOKEN'
  end

  # Return module capabilities
  def self.has_key_read?
    return true
  end

  def self.has_key_write?
    return false
  end

  def self.has_state_read?
    return true
  end

  def self.has_state_store?
    return true
  end

  # Key lookups
  def self.lookup(type, params)
    raise "Lookup parameters must be a Hash" unless params.is_a?(Hash)

    case
    when type == 'artifact'
      required_params = [
        'slug',
        'version',
        'key',
      ]
      required_params.each do |param|
        raise "Missing '#{param}' lookup parameter" unless params.has_key?(param)
      end
      metadata = {}
      metadata = params['metadata'] unless !params['metadata']
      self.get_artifact(params['slug'],params['version'],params['key'], metadata: metadata)
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
      raise "Atlas module does not support the '#{type}' lookup type"
    end
  end
end
