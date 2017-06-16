require_relative '../../../covalence'
require_relative '../data_stores/hiera'
require_relative '../entities/environment'
require_relative 'stack_repository'

module Covalence
  class EnvironmentRepository
    # Do we need all or can it be more focused?
    class << self
      def all(data_store = HieraDB::Client.new(Covalence::CONFIG))
        environments_hash = data_store.hash_lookup('environments')
        raise "Missing 'environments' configuration hash" if environments_hash.empty?

        environments_hash.map do |environment_name, stack_names|
          stacks = stack_names.map do |stack_name|
            StackRepository.find(data_store, environment_name, stack_name)
          end.compact

          check_all_stacks_valid!(environment_name,
                                  stack_names,
                                  stacks)

          Environment.new(name: environment_name,
                          stacks: stacks)
        end
      end

      private

      # Stacks are valid if they map to at least one tool (packer or terraform)
      def check_all_stacks_valid!(environment_name, stack_list, stacks)
        stack_names = stacks.map(&:name)
        invalid_stacks = stack_list - stack_names

        if invalid_stacks.size > 0
          error_string = <<-eos
          Invalid stack(s) #{invalid_stacks} for environment #{environment_name}.
          eos
          raise error_string.strip
        end
      end

    end
  end
end
