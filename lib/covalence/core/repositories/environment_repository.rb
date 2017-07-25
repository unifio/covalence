require_relative '../../../covalence'
require_relative '../data_stores/hiera'
require_relative '../entities/environment'
require_relative 'stack_repository'

module Covalence
  class EnvironmentRepository
    class << self
      def find_all(data_store = HieraDB::Client.new(Covalence::CONFIG))
        environments_hash = lookup_environments(data_store)

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

      def find_filtered(task, data_store = HieraDB::Client.new(Covalence::CONFIG))
        environments_hash = lookup_environments(data_store)
        env_request = task['environment']
        stk_request = task['stack']

        if (env_request.nil? || !environments_hash.has_key?(env_request))
          if RESERVED_NS.include?(env_request)
            return Array.new(1, Environment.new(name: env_request,
                                     stacks: stk_request))
          else
            raise "'#{env_request}' not found in environments"
          end
        end

        stacks = nil
        if (!stk_request.nil? && environments_hash[env_request].include?(stk_request))
          stack_list = Array.new(1, stk_request)
          stacks = Array.new(1, StackRepository.find(data_store, env_request, stk_request))
        else
          stack_list = environments_hash[env_request]
          stacks = stack_list.map do |stack_name|
            StackRepository.find(data_store, env_request, stack_name)
          end.compact
        end

        check_all_stacks_valid!(env_request,
                                stack_list,
                                stacks)

        Array.new(1, Environment.new(name: env_request,
                                     stacks: stacks))
      end

      def populate_stack(stack, data_store = HieraDB::Client.new(Covalence::CONFIG))
        StackRepository.populate(data_store, stack)
      end

      private

      def lookup_environments(data_store)
        environments_hash = data_store.hash_lookup('environments')
        raise "Missing 'environments' configuration hash" if environments_hash.empty?
        environments_hash
      end

      # Stacks are valid if they map to at least one tool (packer or terraform)
      def check_all_stacks_valid!(environment_name, stack_list, stacks)
        stack_names = stacks.map(&:name)
        logger.debug("All stacks: #{stack_list}")
        logger.debug("Targeted stacks: #{stack_names}")

        invalid_stacks = stack_list - stack_names

        if invalid_stacks.size > 0
          error_string = <<-eos
          Invalid stack(s) #{invalid_stacks} for environment #{environment_name}.
          eos
          raise error_string.strip
        end
      end

      def logger
        Covalence::LOGGER
      end
    end
  end
end
