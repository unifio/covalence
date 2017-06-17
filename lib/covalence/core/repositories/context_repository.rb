require 'active_support/core_ext/object/blank'
require_relative '../entities/context'

module Covalence
  class ContextRepository
    class << self
      def query_by_namespace(data_store, namespace, tool)
        if tool == 'terraform'
          query_tool_by_namespace(data_store, namespace)
        else
          Array.new(1, Context.new())
        end
      end

      private

      def query_tool_by_namespace(data_store, namespace)
        targets = data_store.hash_lookup("#{namespace}::targets", {})
        contexts = targets.map do |name, values|
          next if name.blank?
          Context.new(name: name, values: values)
        end
        contexts.compact!
        # always append blank context at the end.
        contexts << Context.new()
        contexts
      end
    end
  end
end
