require_relative '../entities/context'

class ContextRepository
  def self.query_by_namespace(data_store, namespace)
    targets = data_store.hash_lookup("#{namespace}::targets", {})

    if targets.present?
      return targets.map { |k,v| Context.new(name: k, value: v) }
    else
      return Context.new()
    end
  end
end
