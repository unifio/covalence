require 'rake'
require 'slop'

require_relative '../covalence'
require_relative 'core/repositories/environment_repository'
require_relative 'core/services/terraform_stack_tasks'
require_relative 'core/services/packer_stack_tasks'

module Covalence
  class EnvironmentTasks
    include Rake::DSL

    attr_reader :logger

    def initialize
      @logger = Covalence::LOGGER
    end

    # :reek:NestedIterators
    # :reek:TooManyStatements
    def run
      task = get_task_attr(ARGV.first)
      if !task.empty?
        environments = EnvironmentRepository.find_filtered(task)
      else
        environments = EnvironmentRepository.find_all
      end

      if !task.has_key? 'environment'
        all_namespace_terraform_tasks(environments)
      end

      environments.each do |environment|
        # We do not want to render individual tasks for the reserved 'ci' and 'spec' namespaces, or any other specified with COVALENCE_RESERVED_NAMESPACE
        break if RESERVED_NS.include?(task['environment'])

        next if task.has_key? 'environment' && environment.name != task['environment']
        logger.debug("Rendering #{environment.name} environment tasks")
        environment_namespace_terraform_tasks(environment)
        environment_namespace_packer_tasks(environment)

        environment.stacks.each do |stack|
          next if task.has_key? 'stack' && stack.name != task['stack']
          logger.debug("Rendering #{stack.name} stack tasks")
          EnvironmentRepository.populate_stack(stack)
          case stack.type
          when 'terraform'
            tf_tasks = TerraformStackTasks.new(stack)
            stack_namespace_terraform_tasks(tf_tasks)

            stack.contexts.each do |context|
              context_namespace_terraform_tasks(tf_tasks, context)
            end
          when 'packer'
            packer_tasks = PackerStackTasks.new(stack)

            stack.contexts.each do |context|
              context_namespace_packer_tasks(packer_tasks, context)
            end
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

      desc "Apply changes to the #{generate_rake_taskname(stack_name, context_name)} stack of the #{environment_name} environment"
      task generate_rake_taskname(environment_name, stack_name, context_name, "apply") do
        tf_tasks.context_apply(target_args, get_runtime_args)
      end

      desc "Destroy the #{generate_rake_taskname(stack_name, context_name)} stack of the #{environment_name} environment"
      task generate_rake_taskname(environment_name, stack_name, context_name, "destroy") do
        tf_tasks.context_destroy(target_args, get_runtime_args)
      end

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
    end

    def context_namespace_packer_tasks(packer_tasks, context)
      target_args = context.to_packer_command_options
      context_name = context.name
      stack_name = packer_tasks.stack_name
      environment_name = packer_tasks.environment_name

      desc "Build the #{generate_rake_taskname(stack_name, context_name)} packer stack of the #{environment_name} environment"
      task generate_rake_taskname(environment_name, stack_name, context_name, "packer-build") do
        custom_opts = Slop.parse(get_runtime_args, { suppress_errors: true, banner: false })
        packer_tasks.context_build(target_args, custom_opts.args)
      end

      desc "Inspect the #{generate_rake_taskname(stack_name, context_name)} packer stack of the #{environment_name} environment"
      task generate_rake_taskname(environment_name, stack_name, context_name, "packer-inspect") do
        packer_tasks.context_inspect(target_args)
      end

      #desc "Push the #{stack_name} packer stack of the #{environment_name} environment"
      #TODO: deferred until someone asks for this

      desc "Validate the #{generate_rake_taskname(stack_name, context_name)} packer stack of the #{environment_name} environment"
      task generate_rake_taskname(environment_name, stack_name, context_name, "packer-validate") do
        custom_opts = Slop.parse(get_runtime_args, { suppress_errors: true, banner: false })
        packer_tasks.context_validate(target_args, custom_opts.args)
      end

      desc "Export the #{stack_name} stack of the #{environment_name} environment to #{Covalence::STACK_EXPORT}/packer"
      task generate_rake_taskname(environment_name, stack_name, "packer_stack_export") do
        packer_tasks.packer_stack_export()
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

      desc "Refresh the #{stack_name} stack of the #{environment_name} environment"
      task generate_rake_taskname(environment_name, stack_name, "refresh") do
        tf_tasks.stack_refresh
      end

      desc "Synchronize state stores for the #{stack_name} stack of the #{environment_name} environment"
      task generate_rake_taskname(environment_name, stack_name, "sync") do
        tf_tasks.stack_sync
      end

      desc "Verify the #{stack_name} stack of the #{environment_name} environment"
      # Maybe verify_local to highlight that it skips pulling in remote state
      task generate_rake_taskname(environment_name, stack_name, "verify") do
        _tmp_dir = Dir.mktmpdir
        tf_tasks.stack_verify(_tmp_dir)
      end

      desc "Shell into the #{stack_name} stack of the #{environment_name} environment"
      task generate_rake_taskname(environment_name, stack_name, "shell") do
        tf_tasks.stack_shell
      end

      desc "Export the #{stack_name} stack of the #{environment_name} environment to #{Covalence::STACK_EXPORT}/terraform"
      task generate_rake_taskname(environment_name, stack_name, "stack_export") do
        tf_tasks.stack_export
      end

    end

    # :reek:TooManyStatements
    # :reek:DuplicateMethodCall
    # :reek:FeatureEnvy
    # rubocop:disable Metrics/MethodLength
    def environment_namespace_terraform_tasks(environ)
      desc "Clean the #{environ.name} environment"
      task "#{environ.name}:clean" do
        environ.stacks.each { |stack| invoke_rake_task(environ.name, stack.name, "clean") if stack.type == 'terraform' }
      end

      desc "Format the #{environ.name} environment"
      task "#{environ.name}:format" do
        environ.stacks.each { |stack| invoke_rake_task(environ.name, stack.name, "format") if stack.type == 'terraform' }
      end

      desc "Refresh the #{environ.name} environment"
      task "#{environ.name}:refresh" do
        environ.stacks.each { |stack| invoke_rake_task(environ.name, stack.name, "refresh") if stack.type == 'terraform' }
      end

      desc "Verify the #{environ.name} environment"
      task "#{environ.name}:verify" do
        environ.stacks.each { |stack| invoke_rake_task(environ.name, stack.name, "verify") if stack.type == 'terraform' }
      end

      ## Tasks that support multiple contexts
      desc "Apply changes to the #{environ.name} environment"
      task "#{environ.name}:apply" do
        environ.stacks.each do |stack|
          stack.contexts.each do |context|
            invoke_rake_task(environ.name, stack.name, context.name, "apply") if stack.type == 'terraform'
          end
        end
      end

      desc "Destroy the #{environ.name} environment"
      task "#{environ.name}:destroy" do
        environ.stacks.reverse.each do |stack|
          stack.contexts.each do |context|
            invoke_rake_task(environ.name, stack.name, context.name, "destroy") if stack.type == 'terraform'
          end
        end
      end

      desc "Create execution plan for the #{environ.name} environment"
      task "#{environ.name}:plan" do
        environ.stacks.each do |stack|
          stack.contexts.each do |context|
            invoke_rake_task(environ.name, stack.name, context.name, "plan") if stack.type == 'terraform'
          end
        end
      end

      desc "Create destruction plan for the #{environ.name} environment"
      task "#{environ.name}:plan_destroy" do
        environ.stacks.reverse.each do |stack|
          stack.contexts.each do |context|
            invoke_rake_task(environ.name, stack.name, context.name, "plan_destroy") if stack.type == 'terraform'
          end
        end
      end

      desc "Synchronize state stores for the #{environ.name} environment"
      task "#{environ.name}:sync" do
        environ.stacks.each { |stack| invoke_rake_task(environ.name, stack.name, "sync") if stack.type == 'terraform' }
      end
    end

    # :reek:TooManyStatements
    # :reek:DuplicateMethodCall
    # :reek:FeatureEnvy
    # rubocop:disable Metrics/MethodLength
    def environment_namespace_packer_tasks(environ)
      desc "Build the #{environ.name} environment"
      task "#{environ.name}:packer-build" do
        environ.stacks.each do |stack|
          stack.contexts.each do |context|
            invoke_rake_task(environ.name, stack.name, context.name, "packer-build") if stack.type == 'packer'
          end
        end
      end

      desc "Inspect the #{environ.name} environment"
      task "#{environ.name}:packer-inspect" do
        environ.stacks.each do |stack|
          stack.contexts.each do |context|
            invoke_rake_task(environ.name, stack.name, context.name, "packer-inspect") if stack.type == 'packer'
          end
        end
      end

      desc "Validate the #{environ.name} environment"
      task "#{environ.name}:packer-validate" do
        environ.stacks.each do |stack|
          stack.contexts.each do |context|
            invoke_rake_task(environ.name, stack.name, context.name, "packer-validate") if stack.type == 'packer'
          end
        end
      end
    end

    # :reek:TooManyStatements
    def all_namespace_terraform_tasks(environments)
      desc "Clean all environments"
      task "all:clean" do
        environments.each { |environ| invoke_rake_task(environ.name, "clean") }
      end

      desc "Format all environments"
      task "all:format" do
        environments.each { |environ| invoke_rake_task(environ.name, "format") }
      end

      desc "Plan all environments"
      task "all:plan" do
        environments.each { |environ| invoke_rake_task(environ.name, "plan") }
      end

      desc "Refresh all environments"
      task "all:refresh" do
        environments.each { |environ| invoke_rake_task(environ.name, "refresh") }
      end

      desc "Verify all environments"
      task "all:verify" do
        environments.each { |environ| invoke_rake_task(environ.name, "verify") }
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

    def get_task_attr(input)
      logger.info("Task: #{input}")
      task = input.to_s.split(':')
      task_comps = Hash.new
      return task_comps if task.length <= 1 || task[0] == 'all'

      if task.length >= 2
        task_comps['environment'] = task[0]
        logger.info("Applying environment filter: #{task[0]}")
      end
      if task.length >= 3
        task_comps['stack'] = task[1]
        logger.info("Applying stack filter: #{task[1]}")
      end

      task_comps
    end

  end
end

Covalence::EnvironmentTasks.new.run
