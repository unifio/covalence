require 'yaml'
require 'hiera'

module HieraDB

  class Client
    def initialize(config)
      @client = Hiera.new(:config => config)
    end

    def set_scope(env, stack)
      @scope = {
        "environment" => env,
        "stack" => stack
      }
    end

    def lookup(key)
      @client.lookup(key, nil, @scope)
    end

    def hash_lookup(key)
      @client.lookup(key, nil, @scope, order_overide = nil, resolution_type = :hash)
    end

    def array_lookup(key)
      @client.lookup(key, nil, @scope, order_overide = nil, resolution_type = :array)
    end
  end

  # Return module capabilities
  def self.has_key_read?
    return false
  end

  def self.has_key_write?
    return false
  end

  def self.has_state_read?
    return false
  end

  def self.has_state_store?
    return false
  end

end
