require 'tempfile'
require_relative '../../../covalence'
require_relative '../cli_wrappers/packer_cli'

module Covalence
  class PackerStackTasks

    def initialize(stack)
      @path = File.expand_path(File.join(Covalence::PACKER, stack.module_path))
      @stack = stack
      @template = "#{@path}/#{stack.packer_template}"
    end

    def stack_name
      stack.name
    end

    def environment_name
      stack.environment_name
    end

    def context_build(*additional_args)
      Dir.mktmpdir do |tmpdir|
        populate_workspace(tmpdir)
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"

          stack.materialize_cmd_inputs(tmpdir)
          args = collect_args(stack.args,
                              additional_args,
                              "-var-file=covalence-inputs.json")

          call_packer_cmd("packer_build", args)
        end
      end
    end

    def context_inspect(*additional_args)
      Dir.mktmpdir do |tmpdir|
        populate_workspace(tmpdir)
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"

          call_packer_cmd("packer_inspect", [])
        end
      end
    end

    def context_validate(*additional_args)
      Dir.mktmpdir do |tmpdir|
        populate_workspace(tmpdir)
        Dir.chdir(tmpdir) do
          logger.info "In #{tmpdir}:"

          stack.materialize_cmd_inputs(tmpdir)
          args = collect_args(stack.args,
                              additional_args,
                              "-var-file=covalence-inputs.json")

          call_packer_cmd("packer_validate", args)
        end
      end
    end

    # :reek:TooManyStatements
    def packer_stack_export()
        packer_stack_export_init(File.expand_path(File.join(Covalence::STACK_EXPORT,'packer',stack.full_name))).each do |stackdir|
          populate_workspace(stackdir)
          stack.materialize_cmd_inputs(stackdir)
          logger.info "Exported to #{stackdir}:"
        end
    end
    private
    attr_reader :template_path, :stack

    def populate_workspace(workspace)
      # Copy module to the workspace
      FileUtils.copy_entry @path, workspace

      # Copy any dependencies to the workspace
      @stack.dependencies.each do |dep|
        logger.info "Copying '#{dep}' dependency to #{workspace}"
        dep_path = File.expand_path(File.join(Covalence::PACKER, dep))
        FileUtils.cp_r dep_path, workspace
      end
    end

    def call_packer_cmd(packer_cmd, args)
      if template_is_yaml?(@template)
        config = YAML.load_file(@template).to_json
        logger.info "\nGenerated build template:\n\n#{config}"
        File.open('covalence-packer-template.json','w') {|f| f.write(config)}

        PackerCli.public_send(packer_cmd.to_sym, 'covalence-packer-template.json', args: args)
      else
        PackerCli.public_send(packer_cmd.to_sym, @template, args: args)
      end
    end

    def template_is_yaml?(template)
      %w(.yaml .yml).include?(File.extname(template))
    end

    def collect_args(*args)
      args.flatten.compact.reject(&:empty?).map(&:strip)
    end

    # :reek:BooleanParameter
    def packer_stack_export_init(stackdir, dry_run: false, verbose: true)
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
  end
end
