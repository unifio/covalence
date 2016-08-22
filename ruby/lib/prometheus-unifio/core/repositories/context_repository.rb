require_relative '../entities/context'

class ContextRepository
  def self.query_by_namespace(data_store, namespace)
    targets = data_store.hash_lookup("#{namespace}::targets", {})

    if targets.present?
      return targets.map { |name, values| Context.new(name: name, values: values) }
    else
      return Context.new()
    end
  end
end
