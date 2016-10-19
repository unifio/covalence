require_relative '../../../covalence'
require_relative '../cli_wrappers/terraform_cli'

module Covalence
  class TerraformStackTasks

    def initialize(stack)
      @path = File.expand_path(File.join(Covalence::TERRAFORM, stack.tf_module))

      # Primary state store assumption
      @store_args = stack.state_stores.first.get_config
      @stack = stack
    end

    def stack_name
      stack.name
    end

    def environment_name
      stack.environment_name
    end

    def stack_clean
      TerraformCli.terraform_clean(path)
    end

    def stack_format
      TerraformCli.terraform_fmt(path)
    end

    # :reek:TooManyStatements
    def stack_verify
      TerraformCli.terraform_clean(path)

      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"
          TerraformCli.terraform_get(path)
          TerraformCli.terraform_validate(path)
          args = collect_args(stack.materialize_cmd_inputs,
                              "-input=false",
                              "-module-depth=-1",
                              stack.args)

          TerraformCli.terraform_plan(path, args: args)
        end
      end
    end

    # :reek:TooManyStatements
    def stack_sync
      # might want some control/logic around which one is the source of truth other than the first
      TerraformCli.terraform_clean(path)

      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"
          TerraformCli.terraform_remote_config(path, args: store_args)

          stack.state_stores.drop(1).each do |store|
            TerraformCli.terraform_remote_config(path, args: '-disable', ignore_exitcode: true)
            TerraformCli.terraform_remote_config(path, args: "#{store.get_config} -pull=false")
            TerraformCli.terraform_remote_push(path)
          end
        end
      end
    end

    # :reek:TooManyStatements
    def context_plan(*additional_args)
      TerraformCli.terraform_clean(path)

      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"
          TerraformCli.terraform_get(path)

          TerraformCli.terraform_remote_config(path, args: store_args.split(" "))
          TerraformCli.terraform_remote_config(path, args: ["-disable"], ignore_exitcode: true)
          args = collect_args(stack.materialize_cmd_inputs,
                              "-input=false",
                              "-module-depth=-1",
                              stack.args,
                              additional_args)

          TerraformCli.terraform_plan(path, args: args)
        end
      end
    end

    # :reek:TooManyStatements
    def context_plan_destroy(*additional_args)
      TerraformCli.terraform_clean(path)

      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"
          TerraformCli.terraform_get(path)

          TerraformCli.terraform_remote_config(path, args: store_args.split(" "))
          TerraformCli.terraform_remote_config(path, args: ["-disable"], ignore_exitcode: true)
          args = collect_args(stack.materialize_cmd_inputs,
                              "-destroy",
                              "-input=false",
                              "-module-depth=-1",
                              stack.args,
                              additional_args)

          TerraformCli.terraform_plan(path, args: args)
        end
      end
    end

    # :reek:TooManyStatements
    def context_apply(*additional_args)
      TerraformCli.terraform_clean(path)

      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"

          TerraformCli.terraform_get(path)
          TerraformCli.terraform_remote_config(path, args: store_args)
          apply_args = collect_args(stack.materialize_cmd_inputs,
                                    stack.args,
                                    additional_args)
          args = collect_args(apply_args,
                              "-input=false",
                              "-module-depth=-1")

          TerraformCli.terraform_plan(path, args: args)
          TerraformCli.terraform_apply(path, args: apply_args)
        end
      end
    end

    # :reek:TooManyStatements
    def context_destroy(target_args, *additional_args)
      TerraformCli.terraform_clean(path)

      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"

          TerraformCli.terraform_get(path)
          TerraformCli.terraform_remote_config(path, args: store_args)
          base_args = collect_args(stack.materialize_cmd_inputs, stack.args, target_args)

          plan_args = collect_args(base_args,
                              "-destroy",
                              "-input=false",
                              "-module-depth=-1")
          destroy_args = collect_args(base_args,
                                      additional_args,
                                      "-force")

          TerraformCli.terraform_plan(path, args: plan_args)
          TerraformCli.terraform_destroy(path, args: destroy_args)
        end
      end
    end

    private
    attr_reader :path, :stack, :store_args

    def logger
      Covalence::LOGGER
    end

    # :reek:FeatureEnvy
    def collect_args(*args)
      args.flatten.compact.reject(&:empty?).map(&:strip)
    end
  end
end
