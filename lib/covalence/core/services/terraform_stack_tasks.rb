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
      TerraformCli.terraform_clean(@path)
    end

    def stack_format
      TerraformCli.terraform_fmt(@path)
    end

    # :reek:TooManyStatements
    def stack_verify
      Dir.mktmpdir do |tmpdir|
        FileUtils.copy_entry @path, tmpdir
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"

          TerraformCli.terraform_get(@path)
          TerraformCli.terraform_init

          TerraformCli.terraform_validate

          args = collect_args(stack.materialize_cmd_inputs,
                              "-input=false",
                              stack.args)

          TerraformCli.terraform_plan(args: args)
        end
      end
    end

    # :reek:TooManyStatements
    def stack_refresh
      Dir.mktmpdir do |tmpdir|
        FileUtils.copy_entry @path, tmpdir
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"

          # Create the state configuration file
          logger.info "\nState store configuration:\n\n#{@store_args}"
          File.open('state.tf','w') {|f| f.write(@store_args)}

          TerraformCli.terraform_get(@path)
          TerraformCli.terraform_refresh
        end
      end
    end

    # :reek:TooManyStatements
    def stack_sync
      Dir.mktmpdir do |tmpdir|
        FileUtils.copy_entry @path, tmpdir
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"

          # Create the state configuration file
          logger.info "\nState store configuration:\n\n#{@store_args}"
          File.open('state.tf','w') {|f| f.write(@store_args)}

          TerraformCli.terraform_init

          stack.state_stores.drop(1).each do |store|
            args = store.get_config
            # Update the state configuration and reinitialize
            logger.info "\nState store configuration:\n\n#{args}"
            File.open('state.tf','w') {|f| f.write(args)}
            TerraformCli.terraform_init("-force-copy")
          end
        end
      end
    end

    # :reek:TooManyStatements
    def context_plan(*additional_args)
      Dir.mktmpdir do |tmpdir|
        FileUtils.copy_entry @path, tmpdir
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"

          # Create the state configuration file
          logger.info "\nState store configuration:\n\n#{@store_args}"
          File.open('state.tf','w') {|f| f.write(@store_args)}

          TerraformCli.terraform_get(@path)
          TerraformCli.terraform_init

          args = collect_args(stack.materialize_cmd_inputs,
                              "-input=false",
                              stack.args,
                              additional_args)

          TerraformCli.terraform_plan(args: args)
        end
      end
    end

    # :reek:TooManyStatements
    def context_plan_destroy(*additional_args)
      Dir.mktmpdir do |tmpdir|
        FileUtils.copy_entry @path, tmpdir
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"

          # Create the state configuration file
          logger.info "\nState store configuration:\n\n#{@store_args}"
          File.open('state.tf','w') {|f| f.write(@store_args)}

          TerraformCli.terraform_get(@path)
          TerraformCli.terraform_init

          args = collect_args(stack.materialize_cmd_inputs,
                              "-destroy",
                              "-input=false",
                              stack.args,
                              additional_args)

          TerraformCli.terraform_plan(args: args)
        end
      end
    end

    # :reek:TooManyStatements
    def context_apply(*additional_args)
      Dir.mktmpdir do |tmpdir|
        FileUtils.copy_entry @path, tmpdir
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"

          # Create the state configuration file
          logger.info "\nState store configuration:\n\n#{@store_args}"
          File.open('state.tf','w') {|f| f.write(@store_args)}

          TerraformCli.terraform_get(@path)
          TerraformCli.terraform_init

          args = collect_args(stack.materialize_cmd_inputs,
                              "-input=false",
                              stack.args,
                              additional_args)

          TerraformCli.terraform_apply(args: args)
        end
      end
    end

    # :reek:TooManyStatements
    def context_destroy(*additional_args)
      Dir.mktmpdir do |tmpdir|
        FileUtils.copy_entry @path, tmpdir
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"

          # Create the state configuration file
          logger.info "\nState store configuration:\n\n#{@store_args}"
          File.open('state.tf','w') {|f| f.write(@store_args)}

          TerraformCli.terraform_get(@path)
          TerraformCli.terraform_init

          args = collect_args(stack.materialize_cmd_inputs,
                              "-input=false",
                              "-force",
                              stack.args,
                              additional_args)

          TerraformCli.terraform_destroy(args: args)
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
