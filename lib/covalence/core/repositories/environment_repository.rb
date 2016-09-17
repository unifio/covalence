require_relative '../../../covalence'
require_relative '../data_stores/hiera'
require_relative '../entities/environment'
require_relative 'stack_repository'

module Covalence
  class EnvironmentRepository
    # Do we need all or can it be more focused?
    def self.all(data_store = HieraDB::Client.new(Covalence::CONFIG))
      environments_hash = data_store.hash_lookup('environments')
      raise "Missing 'environments' configuration hash" if environments_hash.empty?

      environments_hash.map do |environment_name, stack_names|
        stacks = stack_names.map do |stack_name|
          StackRepository.find(data_store, environment_name, stack_name)
        end

        packer_stacks = stack_names.map do |stack_name|
          StackRepository.packer_find(data_store, environment_name, stack_name)
        end.compact

        Environment.new(name: environment_name,
                        stacks: stacks,
                        packer_stacks: packer_stacks)
      end
    end
  end
end
