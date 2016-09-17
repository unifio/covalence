require 'active_support/core_ext/object/blank'
require_relative '../entities/state_store'

module Covalence
  # todo: monitor behavior forking to determine when the split the class
  class StateStoreRepository
    class << self
      def query_terraform_by_stack_name(data_store, stack_name)
        query_tool_by_stack_name(state_store_key['terraform'], data_store, stack_name)
      end

      def query_packer_by_stack_name(data_store, stack_name)
        query_tool_by_stack_name(state_store_key['packer'], data_store, stack_name)
      end

      private

      def state_store_key
        @state_store_key ||= {
          'terraform' => 'state',
          'packer' => 'packer-state'
        }
      end

      def query_tool_by_stack_name(tool_key, data_store, stack_name)
        stores = data_store.lookup("#{stack_name}::#{tool_key}", [])
        if (stores.blank? && tool_key == 'state')
          raise "State store array cannot be empty"
        end
        stores.map do |store|
          StateStore.new(
            backend: store.keys.first,
            params: store.values.first
          )
        end
      end
    end
  end
end
