require 'rake'
require 'slop'

require_relative '../covalence'
require_relative 'core/repositories/environment_repository'
require_relative 'core/services/terraform_stack_tasks'

module Covalence
  class EnvironmentTasks
    include Rake::DSL

    attr_reader :environments, :logger

    def initialize
      @environments = EnvironmentRepository.all
      @logger = Covalence::LOGGER
    end

    # :reek:NestedIterators
    # :reek:TooManyStatements
    def run
      all_namespace_terraform_tasks
      environments.each do |environment|
        environment_namespace_terraform_tasks(environment)

        environment.stacks.each do |stack|
          tf_tasks = TerraformStackTasks.new(stack)
          stack_namespace_terraform_tasks(tf_tasks)

          stack.contexts.each do |context|
            context_namespace_terraform_tasks(tf_tasks, context)
          end
        end
      end
    end

    private
    # :reek:TooManyStatements
    def context_namespace_terraform_tasks(tf_tasks, context)
      target_args = context.to_command_options
      context_name = context.name
      stack_name = tf_tasks.stack_name
      environment_name = tf_tasks.environment_name

      desc "Create execution plan for the #{generate_rake_taskname(stack_name, context_name)} stack of the #{environment_name} environment"
      task generate_rake_taskname(environment_name, stack_name, context_name, "plan") do |args|
        custom_opts = Slop.parse(get_runtime_args, { suppress_errors: true, banner: false }) do |o|
          o.bool '-nd', '--no-drift', 'enable \'-detailed-exitcode\''
        end

        runtime_args = []
        if custom_opts.no_drift?
          runtime_args << "-detailed-exitcode"
        end
        runtime_args += custom_opts.args
        tf_tasks.context_plan(target_args, runtime_args)
      end

      desc "Create destruction plan for the #{generate_rake_taskname(stack_name, context_name)} stack of the #{environment_name} environment"
      task generate_rake_taskname(environment_name, stack_name, context_name, "plan_destroy") do
        tf_tasks.context_plan_destroy(target_args, get_runtime_args)
      end

      desc "Apply changes to the #{generate_rake_taskname(stack_name, context_name)} stack of the #{environment_name} environment"
      task generate_rake_taskname(environment_name, stack_name, context_name, "apply") do
        tf_tasks.context_apply(target_args, get_runtime_args)
      end

      desc "Destroy the #{generate_rake_taskname(stack_name, context_name)} stack of the #{environment_name} environment"
      task generate_rake_taskname(environment_name, stack_name, context_name, "destroy") do
        tf_tasks.context_destroy(target_args, get_runtime_args)
      end
    end

    # :reek:TooManyStatements
    def stack_namespace_terraform_tasks(tf_tasks)
      stack_name = tf_tasks.stack_name
      environment_name = tf_tasks.environment_name

      desc "Clean the #{stack_name} stack of the #{environment_name} environment"
      task generate_rake_taskname(environment_name, stack_name, "clean") do
        tf_tasks.stack_clean
      end

      desc "Format the #{stack_name} stack of the #{environment_name} environment"
      task generate_rake_taskname(environment_name, stack_name, "format") do
        tf_tasks.stack_format
      end

      desc "Synchronize state stores for the #{stack_name} stack of the #{environment_name} environment"
      task generate_rake_taskname(environment_name, stack_name, "sync") do
        tf_tasks.stack_sync
      end

      desc "Verify the #{stack_name} stack of the #{environment_name} environment"
      # Maybe verify_local to highlight that it skips pulling in remote state
      task generate_rake_taskname(environment_name, stack_name, "verify") do
        tf_tasks.stack_verify
      end

      desc "Refresh the #{stack_name} stack of the #{environment_name} environment"
      task generate_rake_taskname(environment_name, stack_name, "refresh") do
        tf_tasks.stack_refresh
      end
    end

    # :reek:TooManyStatements
    # :reek:DuplicateMethodCall
    # :reek:FeatureEnvy
    # rubocop:disable Metrics/MethodLength
    def environment_namespace_terraform_tasks(environ)
      desc "Clean the #{environ.name} environment"
      task "#{environ.name}:clean" do
        environ.stacks.each { |stack| invoke_rake_task(environ.name, stack.name, "clean") }
      end

      desc "Verify the #{environ.name} environment"
      task "#{environ.name}:verify" do
        environ.stacks.each { |stack| invoke_rake_task(environ.name, stack.name, "verify") }
      end

      desc "Format the #{environ.name} environment"
      task "#{environ.name}:format" do
        environ.stacks.each { |stack| invoke_rake_task(environ.name, stack.name, "format") }
      end

      desc "Refresh the #{environ.name} environment"
      task "#{environ.name}:refresh" do
        environ.stacks.each { |stack| invoke_rake_task(environ.name, stack.name, "refresh") }
      end

      desc "Create execution plan for the #{environ.name} environment"
      task "#{environ.name}:plan" do
        environ.stacks.each do |stack|
          stack.contexts.each do |context|
            invoke_rake_task(environ.name, stack.name, context.name, "plan")
          end
        end
      end

      desc "Create destruction plan for the #{environ.name} environment"
      task "#{environ.name}:plan_destroy" do
        environ.stacks.reverse.each do |stack|
          stack.contexts.each do |context|
            invoke_rake_task(environ.name, stack.name, context.name, "plan_destroy")
          end
        end
      end

      desc "Apply changes to the #{environ.name} environment"
      task "#{environ.name}:apply" do
        environ.stacks.each do |stack|
          stack.contexts.each do |context|
            invoke_rake_task(environ.name, stack.name, context.name, "apply")
          end
        end
      end

      desc "Destroy the #{environ.name} environment"
      task "#{environ.name}:destroy" do
        environ.stacks.reverse.each do |stack|
          stack.contexts.each do |context|
            invoke_rake_task(environ.name, stack.name, context.name, "destroy")
          end
        end
      end

      desc "Synchronize state stores for the #{environ.name} environment"
      task "#{environ.name}:sync" do
        environ.stacks.each { |stack| invoke_rake_task(environ.name, stack.name, "sync") }
      end
    end

    # :reek:TooManyStatements
    def all_namespace_terraform_tasks
      desc "Clean all environments"
      task "all:clean" do
        environments.each { |environ| invoke_rake_task(environ.name, "clean") }
      end

      desc "Verify all environments"
      task "all:verify" do
        environments.each { |environ| invoke_rake_task(environ.name, "verify") }

      desc "Plan all environments"
      task "all:plan" do
        environments.each { |environ| invoke_rake_task(environ.name, "plan") }
      end

      desc "Refresh all environments"
      task "all:refresh" do
        environments.each { |environ| invoke_rake_task(environ.name, "refresh") }
      end

      desc "Format all environments"
      task "all:format" do
        environments.each { |environ| invoke_rake_task(environ.name, "format") }
      end
    end

    def generate_rake_taskname(*args)
      args.delete_if(&:empty?).map(&:to_s).join(":")
    end

    def invoke_rake_task(*args)
      task_name = generate_rake_taskname(*args)
      logger.info "rake #{task_name}"
      Rake::Task[task_name].invoke
    end

    def get_runtime_args
      # strips out [<rake_task>, "--"]
      ARGV.drop(2)
    end
  end
end

Covalence::EnvironmentTasks.new.run
