require_relative '../entities/input'

class InputRepository
  def self.query_by_namespace(data_store, namespace)
    data_store.hash_lookup("#{namespace}::vars", {}).map do |k,v|
      Input.new(name: k, raw_value: v)
    end
  end
end
