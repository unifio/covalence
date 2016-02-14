require 'json'
require 'rest-client'

module Atlas
  AtlasTokenMissing = Class.new(StandardError)

  # Default base URL for Atlas.
  URL = "https://atlas.hashicorp.com"

  def self.reset_cache()
    @cache = Hash.new{|h,k| h[k] = Hash.new{|h,k| h[k] = Hash.new}}
  end

  reset_cache

  def self.get_artifact(slug, version, region)
    ensure_atlas_token_set

    @cache[slug][version][region] ||= begin
      # Create and execute HTTP request
      request = "#{URL}/api/v1/artifacts/#{name}/search?version=#{version}&metadata.1.key=region.#{region}"
      headers = {:'X-Atlas-Token' => ENV['ATLAS_TOKEN']}

      begin
        response = RestClient.get request, headers
      rescue RestClient::ExceptionWithResponse => err
        fail "Unable to retrieve ID for artifact '#{name}': " + err.message
      end

      # Parse JSON response
      parsed = JSON.parse(response)
      latest = parsed["versions"].select {|version| version['metadata'].keys.include? "region.#{region}" }.first

      # Return ID for the region specified
      if latest != nil
        latest["metadata"]["region.#{region}"]
      else
        fail "Requested metadata 'region.#{region}' not found"
      end
    end
  end

  def self.get_output(name, stack)
    ensure_atlas_token_set

    @cache[name][stack][0] || begin
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
        @cache[key][stack] = outputs.fetch(key)
      end

      # Check outputs for requested key and return
      if outputs.has_key?(name)
        @cache[name][stack]
      else
        fail("Requested output '#{name}' not found")
      end
    end
  end

  def self.get_state_store(name)
    "-backend-config=\"name=#{name}\" -backend=Atlas"
  end

  def self.ensure_atlas_token_set
    raise AtlasTokenMissing.new("Missing ATLAS_TOKEN environment variable") unless ENV.key? 'ATLAS_TOKEN'
  end
end
