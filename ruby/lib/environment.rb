require 'yaml'
require_relative 'prometheus'
require_relative 'tools/atlas'
require_relative 'tools/consul'

class EnvironmentReader
  def initialize(path = Prometheus::CONFIG)
    @path = path
  end

  def environments
    config = YAML.load_file(@path)
    raise "Missing 'environments' configuration hash" unless config.has_key? 'environments'

    config['environments'].map do |name,stacks|
      Environment.new(name, stacks)
    end
  end
end

class Environment
  attr_reader :name
  def initialize(name, stacks)
    @name = name
    @stacks = stacks
  end

  def to_sym
    @name.to_sym
  end

  def to_s
    @name.to_s
  end

  def stacks
    @stacks.map{|s| Stack.new(s.first.first, self, s.first[1]) }
  end

  class Stack
    attr_reader :name, :environment
    def initialize(name, env, params)
      required_params = [
        'vars',
        'state'
      ]
      required_params.each do |param|
        raise "Missing #{param} hash for the #{name} stack of the #{env} environment" unless params.has_key?(param)
      end

      @name = name
      @environment = env
      @params = params
    end

    def to_sym
      @name.to_sym
    end

    def to_s
      @name.to_s
    end

    def full_name
      "%s-%s" % [@environment, @name]
    end

    def tf_module
      @params['module'] || @name
    end

    def state_stores
      raise "State store array cannot be empty" unless !@params['state'].empty?
      @params['state'].map{|s| StateStore.new(s.first.first, s.first[1]) }
    end

    def vars
      @params['vars']
    end
  end

  class StateStore
    attr_reader :name, :backend
    def initialize(backend, params)
      @backend = backend

      raise "Missing 'name' parameter for the #{backend} state store" unless params.has_key? 'name'
      @name = params['name']
    end

    def to_sym
      @name.to_sym
    end

    def to_s
      @name.to_s
    end

    def config
      if @backend.downcase == 'atlas'
        Atlas::get_state_store(self.to_s)
      elsif @backend.downcase == 'consul'
        Consul::get_state_store(self.to_s)
      end
    end
  end
end
