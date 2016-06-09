require 'yaml'
require 'hiera'

module HieraDB

  # maybe HieraWrapper
  class Client
    attr_reader :scope

    def initialize(config, scope = {})
      @config = config
      @client = Hiera.new(:config => config)
      @scope = scope
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
      @client.lookup(key, default, scope, order_overide = nil, resolution_type = :hash)
    end

    def array_lookup(key, default = nil, scope = @scope)
      @client.lookup(key, default, scope, order_overide = nil, resolution_type = :array)
    end
  end
end
