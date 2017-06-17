require 'json'
require 'yaml'
require_relative '../../../covalence'
require_relative '../entities/input'

module Covalence
  class InputRepository
    class << self
      def query_by_namespace(data_store, namespace, tool)
        results = Hash.new
        if tool == 'terraform'
          results = parse_var_file('terraform', data_store, namespace)
        else
          results = parse_var_file('packer', data_store, namespace)
        end

        results.merge(query_tool_by_namespace(data_store, namespace))
      end

      private

      #TODO: refactor nested conditional
      def parse_var_file(tool, data_store, namespace)
        yaml_ext = %w(yaml yml)
        json_ext = %w(json)

        varfile = data_store.lookup("#{namespace}::vars-file", nil)
        return {} unless varfile
        tool_module_path ="Covalence::#{tool.upcase}".constantize
        varfile = File.expand_path(File.join(tool_module_path, varfile.to_s))
        if (File.file?(varfile) &&
            (yaml_ext + json_ext).include?(File.extname(varfile)[1..-1]))
          if json_ext.include?(File.extname(varfile)[1..-1])
            tmp_hash = JSON.parse(File.read(varfile))
          else
            tmp_hash = YAML.load_file(varfile)
          end

          tmp_hash = tmp_hash.map do |name, raw_value|
            [ name, Input.new(name: name, raw_value: raw_value) ]
          end
          Hash[*tmp_hash.flatten]
        else
          raise ArgumentError, "cannot parse non-yaml or non-json file: #{varfile}"
        end
      end

      def query_tool_by_namespace(data_store, namespace)
        tmp_hash = data_store.hash_lookup("#{namespace}::vars", {}).map do |name, raw_value|
          [ name, Input.new(name: name, raw_value: raw_value) ]
        end
        Hash[*tmp_hash.flatten]
      end
    end
  end
end
