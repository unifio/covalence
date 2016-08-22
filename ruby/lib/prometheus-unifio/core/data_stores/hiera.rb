require_relative '../../../prometheus-unifio'
require 'yaml'
require 'hiera'

module HieraDB
  # TODO: maybe HieraWrapper
  # :reek:DataClump
  class Client
    attr_reader :scope

    def initialize(config, scope = {})
      @config = config
      @scope = scope

      begin
        @client = Hiera.new(:config => config)
      rescue RuntimeError => e
        PrometheusUnifio::LOGGER.error e.message
        exit 1
      end
    end

    def initialize_scope(scope)
      self.class.new(@config, scope)
    end

    def set_scope(env, stack)
      @scope = {
        "environment" => env,
        "stack" => stack
      }
    end

    def lookup(key, default = nil, scope = @scope)
      @client.lookup(key, default, scope)
    end

    def hash_lookup(key, default = nil, scope = @scope)
      # https://github.com/puppetlabs/hiera/blob/d7ed74f4eec8f4fb1aa84cd0e158a595f86debd4/lib/hiera/backend.rb#L241
      # def lookup(key, default, scope, order_override, resolution_type, context = {:recurse_guard => nil})
      @client.lookup(key, default, scope, nil, :hash)
    end

    def array_lookup(key, default = nil, scope = @scope)
      @client.lookup(key, default, scope, nil, :array)
    end
  end
end
