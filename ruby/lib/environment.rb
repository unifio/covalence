require 'yaml'
require_relative 'prometheus-unifio'

Dir[File.expand_path('tools/*.rb', File.dirname(__FILE__))].each do |file|
  require file
end

class EnvironmentReader
  def initialize(config = PrometheusUnifio::CONFIG)
    @db = HieraDB::Client.new(config)
  end

  def environments
    config = @db.hash_lookup('environments')
    raise "Missing 'environments' configuration hash" unless !config.empty?

    config.map do |name,stacks|
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
    @stacks.map{ |s| Stack.new(s, self) }
  end

  class Stack
    attr_reader :name, :environment
    def initialize(name, env, config = PrometheusUnifio::CONFIG)
      data = HieraDB::Client.new(config)
      data.set_scope(env, name)
      raise "Missing 'state' hash for the #{name} stack of the #{env} environment" unless data.lookup("#{name}::state")

      @name = name
      @environment = env
      @data = data
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
      mod = @data.lookup("#{@name}::module")
      mod || @name
    end

    def state_stores
      stores = @data.lookup("#{@name}::state")
      raise "State store array cannot be empty" unless !stores.empty?
      stores.map{|s| StateStore.new(s.first.first, s.first[1]) }
    end

    def args
      args = @data.lookup("#{self.tf_module.gsub('/','::')}::args")
      return args if args != nil
      return ""
    end

    def has_vars?
      vars = @data.lookup("#{self.tf_module.gsub('/','::')}::vars")
      return true if vars.is_a?(Hash) && !vars.empty?
      return false
    end

    def inputs
      inputs = Array.new
      if self.has_vars?
        @data.hash_lookup("#{self.tf_module.gsub('/','::')}::vars").each do |k,v|
          inputs.push(Input.new(k,v))
        end
      end
      return inputs
    end

    def has_targets?
      targets = @data.lookup("#{self.tf_module.gsub('/','::')}::targets")
      return true if targets.is_a?(Hash) && !targets.empty?
      return false
    end

    def contexts
      contexts = Array.new
      if self.has_targets?
        @data.hash_lookup("#{self.tf_module.gsub('/','::')}::targets").each do |k,v|
          contexts.push(Context.new(k,v))
        end
      else
        contexts.push(Context.new('',[]))
      end
      return contexts
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
        backend::get_state_store(@params)
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

    class Context
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

      def namespace
        return "#{self.to_s}:" unless @name == ''
        return self.to_s
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
