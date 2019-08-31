require_relative '../../../covalence'
require_relative '../cli_wrappers/terraform_cli'

module Covalence
  class TerraformStackTasks

    def initialize(stack)
      @path = File.expand_path(File.join(Covalence::TERRAFORM, stack.module_path))
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
    def stack_shell
      Dir.mktmpdir do |tmpdir|
        populate_workspace(tmpdir)
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"

          stack.materialize_state_inputs
          TerraformCli.terraform_get(@path)
          TerraformCli.terraform_init

          stack.materialize_cmd_inputs(tmpdir)

          shell = ENV.fetch('SHELL', 'sh')
          system(shell)
        end
      end
    end

    # :reek:TooManyStatements
    def stack_export
        stack_export_init(File.expand_path(File.join(Covalence::STACK_EXPORT,'terraform',stack.full_name))).each do |stackdir|
          logger.info "Created stackdir: #{stackdir}"
          populate_workspace(stackdir)
          Dir.chdir(stackdir) do
            logger.info "In #{stackdir}:"
            stack.materialize_state_inputs
            TerraformCli.terraform_get(@path)
            TerraformCli.terraform_init
            stack.materialize_cmd_inputs(stackdir)
            logger.info "Exported to #{stackdir}:"
          end
        end
    end

    # :reek:TooManyStatements
    def stack_verify(tmpdir)
      return false if  !TerraformCli.terraform_check_style(@path)

      return false if !TerraformCli.terraform_get(path=@path, workdir=tmpdir)
      populate_workspace(tmpdir)

      return false if !TerraformCli.terraform_init(path: @path, workdir: tmpdir)
      stack.materialize_cmd_inputs(tmpdir)
      args = collect_args("-input=false",
                          stack.args,
                          "-var-file=#{tmpdir}/covalence-inputs.tfvars")

      tf_vers = Gem::Version.new(Covalence::TERRAFORM_VERSION)

      if tf_vers >= Gem::Version.new('0.12.0')
        # >= 0.12 does *not* support validating input vars
        return false if !TerraformCli.terraform_validate(path=tmpdir, workdir=tmpdir, args: stack.args)
      else
        # < 0.12 supports validating input vars
        return false if !TerraformCli.terraform_validate(path=tmpdir, workdir=tmpdir, args: args)
      end

      TerraformCli.terraform_plan(path: @path , workdir: tmpdir, args: args)
    end

    # :reek:TooManyStatements
    def stack_refresh
      Dir.mktmpdir do |tmpdir|
        populate_workspace(tmpdir)
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"

          TerraformCli.terraform_workspace(@stack.workspace) unless stack.workspace.to_s.empty?

          stack.materialize_state_inputs
          TerraformCli.terraform_get(@path)
          TerraformCli.terraform_init

          stack.materialize_cmd_inputs(tmpdir)
          args = collect_args("-input=false",
                              stack.args,
                              "-var-file=covalence-inputs.tfvars")

          TerraformCli.terraform_refresh(args: args)
        end
      end
    end

    # :reek:TooManyStatements
    def stack_sync
      Dir.mktmpdir do |tmpdir|
        populate_workspace(tmpdir)
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"

          TerraformCli.terraform_workspace(@stack.workspace) unless stack.workspace.to_s.empty?

          stack.materialize_state_inputs
          TerraformCli.terraform_get(@path)
          TerraformCli.terraform_init

          stack.state_stores.drop(1).each do |store|
            Covalence::LOGGER.debug("Stack: #{store.inspect}")

            stack.materialize_state_inputs(store: store)
            TerraformCli.terraform_init("-force-copy")
          end
        end
      end
    end

    # :reek:TooManyStatements
    def context_plan(*additional_args)
      Dir.mktmpdir do |tmpdir|
        populate_workspace(tmpdir)
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"

          TerraformCli.terraform_workspace(@stack.workspace) unless stack.workspace.to_s.empty?

          stack.materialize_state_inputs
          TerraformCli.terraform_get(@path)
          TerraformCli.terraform_init

          stack.materialize_cmd_inputs(tmpdir)
          args = collect_args("-input=false",
                              stack.args,
                              additional_args,
                              "-var-file=covalence-inputs.tfvars")

          TerraformCli.terraform_plan(path: @path, workdir: tmpdir, args: args)
        end
      end
    end

    # :reek:TooManyStatements
    def context_plan_destroy(*additional_args)
      Dir.mktmpdir do |tmpdir|
        populate_workspace(tmpdir)
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"

          TerraformCli.terraform_workspace(@stack.workspace) unless stack.workspace.to_s.empty?

          stack.materialize_state_inputs
          TerraformCli.terraform_get(@path)
          TerraformCli.terraform_init

          stack.materialize_cmd_inputs(tmpdir)
          args = collect_args("-destroy",
                              "-input=false",
                              stack.args,
                              additional_args,
                              "-var-file=covalence-inputs.tfvars")

          TerraformCli.terraform_plan(args: args)
        end
      end
    end

    # :reek:TooManyStatements
    def context_apply(*additional_args)
      Dir.mktmpdir do |tmpdir|
        populate_workspace(tmpdir)
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"

          TerraformCli.terraform_workspace(@stack.workspace) unless stack.workspace.to_s.empty?

          stack.materialize_state_inputs
          TerraformCli.terraform_get(@path)
          TerraformCli.terraform_init

          stack.materialize_cmd_inputs(tmpdir)
          args = collect_args("-input=false",
                              "-auto-approve=true",
                              stack.args,
                              additional_args,
                              "-var-file=covalence-inputs.tfvars")

          TerraformCli.terraform_apply(args: args)
        end
      end
    end

    # :reek:TooManyStatements
    def context_destroy(*additional_args)
      Dir.mktmpdir do |tmpdir|
        populate_workspace(tmpdir)
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"

          TerraformCli.terraform_workspace(@stack.workspace) unless stack.workspace.to_s.empty?

          stack.materialize_state_inputs
          TerraformCli.terraform_get(@path)
          TerraformCli.terraform_init

          stack.materialize_cmd_inputs(tmpdir)
          args = collect_args("-input=false",
                              "-auto-approve=true",
                              stack.args,
                              additional_args,
                              "-var-file=covalence-inputs.tfvars")

          TerraformCli.terraform_destroy(args: args)
        end
      end
    end

    private
    attr_reader :path, :stack, :store_args

    def populate_workspace(workspace)
      # Copy module to the workspace
      FileUtils.copy_entry @path, workspace

      # Copy any dependencies to the workspace
      @stack.dependencies.each do |dep|
        dep_path = File.expand_path(File.join(Covalence::TERRAFORM, dep))
        FileUtils.cp_r dep_path, workspace
      end
    end

    # :reek:BooleanParameter
    def stack_export_init(stackdir, dry_run: false, verbose: true)
      if(File.exist?(stackdir))
        logger.info "Deleting before export: #{stackdir}"
        FileUtils.rm_rf(stackdir, {
          noop: dry_run,
          verbose: verbose,
          secure: true,
        })
      end
      logger.info "Creating stack directory: #{stackdir}"
      FileUtils.mkdir_p(stackdir, {
        noop: dry_run,
        verbose: verbose,
      })
    end

    def logger
      Covalence::LOGGER
    end

    # :reek:FeatureEnvy
    def collect_args(*args)
      args.flatten.compact.reject(&:empty?).map(&:strip)
    end
  end
end
