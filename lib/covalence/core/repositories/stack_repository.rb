require 'active_support/core_ext/hash'

require_relative '../../../covalence'
require_relative '../entities/stack'
require_relative 'state_store_repository'
require_relative 'input_repository'
require_relative 'context_repository'

module Covalence
  class StackRepository
    def self.find(data_store, environment_name, stack_name)
      stack_scope = {
        'environment' => environment_name,
        'stack' => stack_name,
      }
      tool = lookup_tool(data_store, stack_scope)
      return if tool.nil?

      stack_data_store = data_store.initialize_scope(stack_scope)
      stack_module = lookup_shared_namespace(stack_data_store, stack_name)
      shared_namespace = stack_module.gsub('/', '::') unless stack_module.nil?

      Stack.new(
        type: tool,
        name: stack_name,
        environment_name: environment_name,
        module_path: stack_module,
        dependencies: lookup_dependencies(stack_data_store, stack_name),
        packer_template: lookup_packer_template(stack_data_store, stack_name),
        state_stores: StateStoreRepository.query_by_stack_name(stack_data_store, stack_name, tool),
        contexts: ContextRepository.query_by_namespace(stack_data_store, shared_namespace, tool),
        inputs: InputRepository.query_by_namespace(stack_data_store, shared_namespace, tool),
        args: find_args_by_namespace(stack_data_store, shared_namespace),
      )
    end

    class << self
      private
      def lookup_packer_template(data_store, stack_name)
        data_store.lookup("#{stack_name}::packer-template", nil)
      end

      def lookup_dependencies(data_store, stack_name)
        data_store.lookup("#{stack_name}::deps", [])
      end

      def lookup_shared_namespace(data_store, stack_name)
        data_store.lookup("#{stack_name}::module", stack_name)
      end

      # maybe arg_string instead of args
      def find_args_by_namespace(data_store, namespace)
        data_store.lookup("#{namespace}::args", "")
      end

      def lookup_tool(data_store, arguments)
        if !data_store.lookup("#{arguments['stack']}::state", nil, arguments).nil?
          return 'terraform'
        elsif !data_store.lookup("#{arguments['stack']}::packer-template", nil, arguments).nil?
          return 'packer'
        else
          logger.debug "#{arguments['environment']}:#{arguments['stack']} is neither a valid Terraform or Packer stack."
          return nil
        end
      end

      def logger
        Covalence::LOGGER
      end
    end
  end
end
