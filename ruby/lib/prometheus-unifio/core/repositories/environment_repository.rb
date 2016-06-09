require_relative '../../../prometheus-unifio'
require_relative '../data_stores/hiera'
require_relative '../entities/environment'
require_relative 'stack_repository'

class EnvironmentRepository
  # Do we need all or can it be more focused?
  def self.all(data_store = HieraDB::Client.new(PrometheusUnifio::CONFIG))
    environments_hash = data_store.hash_lookup('environments')
    raise "Missing 'environments' configuration hash" if environments_hash.empty?

    environments_hash.map do |environment_name, stack_names|
      stacks = stack_names.map { |stack_name| StackRepository.find(data_store, environment_name, stack_name) }
      Environment.new(name: environment_name, stacks: stacks)
    end
  end
end
