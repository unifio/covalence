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
      )
    end

    def self.populate(data_store, stack)
      stack_scope = {
        'environment' => stack.environment_name,
        'stack' => stack.name,
      }
      stack_data_store = data_store.initialize_scope(stack_scope)
      shared_namespace = stack.module_path.gsub('/', '::')

      stack.dependencies = lookup_dependencies(stack_data_store, stack.name)
      stack.packer_template = lookup_packer_template(stack_data_store, stack.name)
      stack.workspace = lookup_workspace(stack_data_store, stack.name)
      stack.state_stores = StateStoreRepository.query_by_stack_name(stack_data_store, stack.name, stack.workspace, stack.type)
      stack.contexts = ContextRepository.query_by_namespace(stack_data_store, shared_namespace, stack.type)
      stack.inputs = InputRepository.query_by_namespace(stack_data_store, shared_namespace, stack.type)
      stack.args = find_args_by_namespace(stack_data_store, shared_namespace)
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

      def lookup_workspace(data_store, stack_name)
        wrkspc = data_store.lookup("#{stack_name}::workspace", "")
        wrkspc = Covalence::Helpers::ShellInterpolation.parse_shell(wrkspc) if wrkspc.to_s.include?("$(")
        return wrkspc
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
