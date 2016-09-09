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
      validate_terraform_stack_scope(data_store, stack_scope)

      stack_data_store = data_store.initialize_scope(stack_scope)
      shared_namespace = lookup_shared_namespace(stack_data_store, stack_name).gsub('/', '::')

      Stack.new(
        type: 'terraform',
        name: stack_name,
        environment_name: environment_name,
        tf_module: lookup_shared_namespace(stack_data_store, stack_name),
        state_stores: StateStoreRepository.query_terraform_by_stack_name(stack_data_store, stack_name),
        contexts: ContextRepository.query_terraform_by_namespace(stack_data_store, shared_namespace),
        inputs: InputRepository.query_terraform_by_namespace(stack_data_store, shared_namespace),
        args: find_args_by_namespace(stack_data_store, shared_namespace),
      )
    end


    def self.packer_find(data_store, environment_name, stack_name)
      stack_scope = {
        'environment' => environment_name,
        'stack' => stack_name,
        'tool' => 'packer'
      }

      stack_data_store = data_store.initialize_scope(stack_scope)
      packer_module = lookup_shared_packer_namespace(stack_data_store, stack_name)
      if (packer_module &&
          (shared_packer_namespace = packer_module.gsub('/', '::')) &&
          (packer_template = find_packer_template_by_namespace(stack_data_store, shared_packer_namespace))
         )

        Stack.new(
          type: 'packer',
          name: stack_name,
          environment_name: environment_name,
          packer_template: packer_template,
          state_stores: StateStoreRepository.query_packer_by_stack_name(stack_data_store, stack_name),
          contexts: ContextRepository.query_packer_by_namespace(stack_data_store, shared_packer_namespace),
          inputs: InputRepository.query_packer_by_namespace(stack_data_store, shared_packer_namespace),
          args: find_args_by_namespace(stack_data_store, shared_packer_namespace),
        )
      end
    end

    class << self
      private
      def find_packer_template_by_namespace(data_store, namespace)
        data_store.lookup("#{namespace}::packer-template", nil)
      end

      def lookup_shared_packer_namespace(data_store, stack_name)
        result = data_store.lookup("#{stack_name}::packer-module", stack_name)
        File.directory?(File.expand_path(File.join(PACKER, result))) ? result : nil
      end

      def lookup_shared_namespace(data_store, stack_name)
        data_store.lookup("#{stack_name}::module", stack_name)
        # verify folder exists?
      end

      # maybe arg_string instead of args
      def find_args_by_namespace(data_store, namespace)
        data_store.lookup("#{namespace}::args", "")
      end

      # :reek:FeatureEnvy
      # :reek:NilCheck
      def validate_terraform_stack_scope(data_store, arguments)
        if data_store.lookup("#{arguments['stack']}::state", nil, arguments).nil?
          raise "#{arguments['stack']} stack missing 'state' hash of the #{arguments['environment']} environment"
        end
      end
    end
  end
end
