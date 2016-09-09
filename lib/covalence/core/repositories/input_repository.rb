require 'json'
require 'yaml'
require_relative '../../../covalence'
require_relative '../entities/input'

module Covalence
  class InputRepository
    class << self
      def query_terraform_by_namespace(data_store, namespace)
        results = parse_var_file('terraform', input_file_key['terraform'], data_store, namespace)
        results.merge(query_tool_by_namespace(input_key['terraform'], data_store, namespace))
      end

      def query_packer_by_namespace(data_store, namespace)
        results = parse_var_file('packer', input_file_key['packer'], data_store, namespace)
        results.merge(query_tool_by_namespace(input_key['packer'], data_store, namespace))
      end

      private

      def input_key
        @input_key ||= {
          'terraform' => 'vars',
          'packer' => 'packer-vars'
        }
      end

      def input_file_key
        @input_file_key ||= {
          'terraform' => 'vars-file',
          'packer' => 'packer-vars-file'
        }
      end

      #TODO: refactor nested conditional
      def parse_var_file(tool, tool_key, data_store, namespace)
        yaml_ext = %w(yaml yml)
        json_ext = %w(json)

        varfile = data_store.lookup("#{namespace}::#{tool_key}", nil)
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
            [ name, Input.new(type: tool, name: name, raw_value: raw_value) ]
          end
          Hash[*tmp_hash.flatten]
        else
          raise ArgumentError, "cannot parse non-yaml or non-json file: #{varfile}"
        end
      end

      def query_tool_by_namespace(tool_key, data_store, namespace)
        tmp_hash = data_store.hash_lookup("#{namespace}::#{tool_key}", {}).map do |name, raw_value|
          [ name, Input.new(name: name, raw_value: raw_value) ]
        end
        Hash[*tmp_hash.flatten]
      end
    end
  end
end
