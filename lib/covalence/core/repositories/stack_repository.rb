require 'active_support/core_ext/hash'

require_relative '../../../covalence'
require_relative '../entities/stack'
require_relative 'state_store_repository'
require_relative 'input_repository'
require_relative 'context_repository'

module Covalence
  class StackRepository
    def self.find(data_store, environment_name, stack_name)
      tool = 'terraform'
      stack_scope = {
        'environment' => environment_name,
        'stack' => stack_name,
        'tool' => tool
      }
      return if invalid_stack_scope(data_store, stack_scope, tool)

      stack_data_store = data_store.initialize_scope(stack_scope)
      terraform_module = lookup_shared_namespace(stack_data_store, stack_name)
      shared_namespace = terraform_module.gsub('/', '::') unless terraform_module.nil?

      Stack.new(
        type: tool,
        name: stack_name,
        environment_name: environment_name,
        module_path: terraform_module,
        dependencies: lookup_dependencies(stack_data_store, stack_name),
        state_stores: StateStoreRepository.query_terraform_by_stack_name(stack_data_store, stack_name),
        contexts: ContextRepository.query_terraform_by_namespace(stack_data_store, shared_namespace),
        inputs: InputRepository.query_terraform_by_namespace(stack_data_store, shared_namespace),
        args: find_args_by_namespace(stack_data_store, shared_namespace),
      )
    end

    def self.packer_find(data_store, environment_name, stack_name)
      tool = 'packer'
      stack_scope = {
        'environment' => environment_name,
        'stack' => stack_name,
        'tool' => tool
      }
      return if invalid_stack_scope(data_store, stack_scope, tool)

      stack_data_store = data_store.initialize_scope(stack_scope)
      packer_module = lookup_shared_namespace(stack_data_store, stack_name)
      shared_namespace = packer_module.gsub('/', '::') unless packer_module.nil?

      Stack.new(
        type: tool,
        name: stack_name,
        environment_name: environment_name,
        module_path: packer_module,
        dependencies: lookup_dependencies(stack_data_store, stack_name),
        packer_template: lookup_packer_template(stack_data_store, stack_name),
        state_stores: StateStoreRepository.query_packer_by_stack_name(stack_data_store, stack_name),
        contexts: ContextRepository.query_packer_by_namespace(stack_data_store, shared_namespace),
        inputs: InputRepository.query_packer_by_namespace(stack_data_store, shared_namespace),
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

      # :reek:FeatureEnvy
      # :reek:NilCheck
      def invalid_stack_scope(data_store, arguments, tool)
        case tool
        when 'terraform'
          if data_store.lookup("#{arguments['stack']}::state", nil, arguments).nil?
            logger.debug"#{arguments['environment']}:#{arguments['stack']} is not a valid Terraform stack ('state' parameter hash unspecified)"
          end
        when 'packer'
          if data_store.lookup("#{arguments['stack']}::packer-template", nil, arguments).nil?
            logger.debug "#{arguments['environment']}:#{arguments['stack']} is not a valid Packer stack ('packer-template' parameter unspecified)"
          end
        else
          logger.debug "#{arguments['environment']}:#{arguments['stack']} is not a valid stack type ('#{tool}' type unsupported)"
        end
      end

      def logger
        Covalence::LOGGER
      end
    end
  end
end
