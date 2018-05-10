require 'active_support/core_ext/object/blank'
require_relative '../entities/state_store'

module Covalence
  # todo: monitor behavior forking to determine when the split the class
  class StateStoreRepository
    class << self
      def query_by_stack_name(data_store, stack_name, stack_workspace, tool)
        if tool == 'terraform'
          query_tool_by_stack_name(data_store, stack_name, stack_workspace)
        else
          return nil
        end
      end

      private

      def query_tool_by_stack_name(data_store, stack_name, stack_workspace)
        stores = data_store.lookup("#{stack_name}::state", [])
        raise "State store array cannot be empty" if stores.blank?
        stores.map do |store|
          StateStore.new(
            backend: store.keys.first,
            params: store.values.first,
            workspace_enabled: !stack_workspace.empty?
          )
        end
      end
    end
  end
end
