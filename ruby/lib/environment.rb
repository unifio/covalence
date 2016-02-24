require 'yaml'
require_relative 'prometheus'

Dir[File.expand_path('tools/*.rb', File.dirname(__FILE__))].each do |file|
  require file
end

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

    def has_vars?
      return true if @params['vars'].is_a?(Hash) && !@params['vars'].empty?
      return false
    end

    def inputs
      artifacts = Array.new
      if self.has_vars?
        @params['vars'].each do |k,v|
          artifacts.push(Input.new(k,v))
        end
      end
      return artifacts
    end

    class StateStore
      attr_reader :name, :backend
      def initialize(backend, params)
        raise "Missing 'name' parameter for the #{backend} state store" unless params.has_key? 'name'
        @backend = backend
        @params = params
      end

      def to_sym
        @params['name'].to_sym
      end

      def to_s
        @params['name'].to_s
      end

      def backend
        @backend.capitalize
      end

      def get_config
        backend = Object::const_get(self.backend)
        raise "#{self.backend} module does not support state storage" unless backend.has_state_store?
        backend::get_state_store(self.to_s)
      end
    end

    class Input
      attr_reader :name
      def initialize(name, params)
        @name = name
        @params = params
      end

      def to_sym
        @name.to_sym
      end

      def to_s
        @name.to_s
      end

      def is_local?
        return true unless @params.is_a?(Hash)
        return false
      end

      def backend
        if !self.is_local?
          raise "Input 'type' not specified" unless @params.has_key? 'type'
          return @params['type'].partition('.')[0].capitalize
        end
        return 'local'
      end

      def type
        if !self.is_local?
          raise "Input 'type' not specified" unless @params.has_key? 'type'
          return @params['type'].partition('.')[2]
        end
        return 'key'
      end

      def value
        @params
      end
    end
  end
end

class InputReader
  def initialize(stack)
    @stack = stack
  end

  def to_h()
    inputs = Hash.new
    if !@stack.inputs.empty?
      @stack.inputs.each do |inp|
        if inp.is_local?
          inputs = inputs.merge({inp.to_s => inp.value})
        else
          backend = Object::const_get(inp.backend)
          raise "#{inp.backend} module does not support key lookup" unless backend.has_key_read?
          inputs = inputs.merge({inp.to_s => backend::lookup(inp.type, inp.value)})
        end
      end
    end
    return inputs
  end
end
