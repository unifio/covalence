require 'active_support/core_ext/object/blank'
require_relative '../entities/context'

module Covalence
  class ContextRepository
    class << self
      def query_terraform_by_namespace(data_store, namespace)
        query_tool_by_namespace(context_key['terraform'], data_store, namespace)
      end

      def query_packer_by_namespace(data_store, namespace)
        query_tool_by_namespace(context_key['packer'], data_store, namespace)
      end

      private

      def context_key
        @context_key ||= {
          'terraform' => 'targets',
          'packer' => 'packer-targets'
        }
      end

      def query_tool_by_namespace(tool_key, data_store, namespace)
        targets = data_store.hash_lookup("#{namespace}::#{tool_key}", {})
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
