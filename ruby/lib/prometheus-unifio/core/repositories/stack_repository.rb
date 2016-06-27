require 'active_support/core_ext/hash'

require_relative '../entities/stack'

require_relative 'state_store_repository'
require_relative 'input_repository'
require_relative 'context_repository'

class StackRepository
  def self.find(data_store, environment_name, stack_name)
    stack_scope = {
      'environment' => environment_name,
      'stack' => stack_name,
    }
    validate_stack_scope(data_store, stack_scope)

    stack_data_store = data_store.initialize_scope(stack_scope)
    shared_namespace = lookup_shared_namespace(stack_data_store).gsub('/', '::')

    Stack.new(
      name: stack_name,
      environment_name: environment_name,
      tf_module: lookup_shared_namespace(stack_data_store),
      state_stores: StateStoreRepository.query_by_stack_name(stack_data_store, stack_name),
      contexts: ContextRepository.query_by_namespace(stack_data_store, shared_namespace),
      inputs: InputRepository.query_by_namespace(stack_data_store, shared_namespace),
      args: find_args_by_namespace(stack_data_store, shared_namespace),
    )
  end

  private
  # stack.tf_module
  def self.lookup_shared_namespace(data_store)
    stack_name = data_store.scope['stack']
    mod = data_store.lookup("#{stack_name}::module", nil)
    mod || stack_name
  end

  def self.find_args_by_namespace(data_store, namespace)
    args = data_store.lookup("#{namespace}::args", nil)
    return (args != nil) ? args : ""
  end

  def self.validate_stack_scope(data_store, arguments)
    required_args = %w(environment stack)
    if required_args & arguments.stringify_keys.keys != required_args
      raise "Missing required args: #{required_args} in arguments: #{arguments}"
    end

    if data_store.lookup("#{arguments['stack']}::state", nil, arguments).nil?
      raise "#{arguments['stack']} stack missing 'state' hash of the #{arguments['environment']} environment"
    end
  end
end
