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

  class Syntax
    def check_yaml(filelist)
      raise "Expected an array of files" unless filelist.is_a?(Array)

      errors = []

      filelist.each do |hiera_file|
        begin
          YAML.load_file(hiera_file)
        rescue Exception => error
          errors << "ERROR: Failed to parse #{hiera_file}: #{error}"
        end
       end

      errors.map! { |e| e.to_s }

      errors
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
