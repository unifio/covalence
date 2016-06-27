require_relative '../entities/state_store'

class StateStoreRepository
  def self.query_by_stack_name(data_store, stack_name)
    stores = data_store.lookup("#{stack_name}::state", nil)
    raise "State store array cannot be empty" if stores.empty?
    stores.map do |s|
      StateStore.new(
        backend: s.keys.first,
        params: s.values.first
      )
    end
  end
end
