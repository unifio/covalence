require_relative '../entities/input'

module PrometheusUnifio
  class InputRepository
    def self.query_by_namespace(data_store, namespace)
      data_store.hash_lookup("#{namespace}::vars", {}).map do |name, raw_value|
        Input.new(name: name, raw_value: raw_value)
      end
    end
  end
end
