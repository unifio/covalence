require 'rake'
require_relative '../covalence'
require_relative 'core/repositories/environment_repository'
require_relative 'core/services/packer_stack_tasks'

# TODO: intentially split from environment_tasks for now since i'm unsure about stability.
module Covalence
  class PackerTasks
    include Rake::DSL

    attr_reader :environments, :logger

    def initialize
      @environments = EnvironmentRepository.all
      @logger = Covalence::LOGGER
    end

    def run
      environments.each do |environment|
        environment.packer_stacks.each do |stack|
          packer_tasks = PackerStackTasks.new(stack)

          stack.contexts.each do |context|
            context_namespace_packer_tasks(packer_tasks, context)
          end
        end
      end
    end

    private

    def context_namespace_packer_tasks(packer_tasks, context)
      target_args = context.to_packer_command_options
      context_name = context.name
      stack_name = packer_tasks.stack_name
      environment_name = packer_tasks.environment_name

      desc "Build the #{generate_rake_taskname(stack_name, context_name)} packer stack(:context) of the #{environment_name} environment"
      task generate_rake_taskname(environment_name, stack_name, context_name, "packer-build") do
        custom_opts = Slop.parse(get_runtime_args, { suppress_errors: true, banner: false })
        packer_tasks.context_build(target_args, custom_opts.args)
      end

      desc "Inspect the #{generate_rake_taskname(stack_name, context_name)} packer stack(:context) of the #{environment_name} environment"
      task generate_rake_taskname(environment_name, stack_name, context_name, "packer-inspect") do
        packer_tasks.context_inspect(target_args)
      end

      #desc "Push the #{stack_name} packer stack of the #{environment_name} environment"
      #TODO: deferred until someone asks for this

      desc "Validate the #{generate_rake_taskname(stack_name, context_name)} packer stack(:context) of the #{environment_name} environment"
      task generate_rake_taskname(environment_name, stack_name, context_name, "packer-validate") do
        custom_opts = Slop.parse(get_runtime_args, { suppress_errors: true, banner: false })
        packer_tasks.context_validate(target_args, custom_opts.args)
      end
    end

    def generate_rake_taskname(*args)
      args.delete_if(&:empty?).map(&:to_s).join(":")
    end

    def get_runtime_args
      # strips out [<rake_task>, "--"]
      ARGV.drop(2)
    end
  end
end

Covalence::PackerTasks.new.run
