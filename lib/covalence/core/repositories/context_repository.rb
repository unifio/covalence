require 'active_support/core_ext/object/blank'
require_relative '../entities/context'

module Covalence
  class ContextRepository
    class << self
      def query_terraform_by_namespace(data_store, namespace)
        query_tool_by_namespace('terraform', data_store, namespace)
      end

      def query_packer_by_namespace(data_store, namespace)
        query_tool_by_namespace('packer', data_store, namespace)
      end

      private

      def query_tool_by_namespace(tool, data_store, namespace)
        targets = data_store.hash_lookup("#{namespace}::targets", {})
        contexts = []
        if tool == "terraform"
          contexts = targets.map do |name, values|
            next if name.blank?
            Context.new(name: name, values: values)
          end
          contexts.compact!
        end
        # always append blank context at the end.
        contexts << Context.new()
        contexts
      end
    end
  end
end
