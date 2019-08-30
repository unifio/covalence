require 'yaml'
require 'fileutils'
require 'tmpdir'
require 'active_support/core_ext/object/blank'
require 'open3'
require 'semantic'

require_relative '../../../covalence'
require_relative 'popen_wrapper'

module Covalence
  class TerraformCli
    def self.require_init()
      if Semantic::Version.new(Covalence::TERRAFORM_VERSION) < Semantic::Version.new("0.9.0")
        raise "Terraform v0.9.0 or newer required"
      else
        cmds_yml = File.expand_path("terraform.yml", __dir__)
      end
      init_terraform_cmds(cmds_yml)
    end

    # :reek:BooleanParameter
    def self.terraform_clean(path, dry_run: false, verbose: true)
      # standard run shouldn't need this since it does a chdir on a temp dir anyway
      # something about cln_cmd when working with docker images
      targets = [ File.join(File.expand_path(path), ".terraform") ] +
        Dir.glob(File.join(File.expand_path(path), "*.tfstate*"))

      FileUtils.rm_rf(targets, {
        noop: dry_run,
        verbose: verbose,
        secure: true,
      })
    end

    def self.terraform_check_style(path)
      cmd = [Covalence::TERRAFORM_CMD, "fmt", "-check"]

      output = PopenWrapper.run(
          cmd,
          path,
          '',
          ignore_exitcode: false)
      (output == 0)
    end

    def self.terraform_init(path: '', workdir: Dir.pwd, args: '', ignore_exitcode: false)
      if ENV['TF_PLUGIN_LOCAL'] == 'true'
        cmd = [Covalence::TERRAFORM_CMD, "init", "-get-plugins=false", "-get=false", "-input=false", "-plugin-dir=#{Covalence::TERRAFORM_PLUGIN_CACHE}"]
      else
        cmd = [Covalence::TERRAFORM_CMD, "init", "-get-plugins=#{Covalence::TERRAFORM_GET_PLUGINS ? 'true' : 'false'}", "-get=false", "-input=false"]
      end

      output = PopenWrapper.run(
        cmd,
        path,
        args,
        ignore_exitcode: ignore_exitcode,
        workdir: workdir)
      (output == 0)
    end

    def self.terraform_get(path=Dir.pwd, workdir=Dir.pwd, args: '', ignore_exitcode: false)
      cmd = [Covalence::TERRAFORM_CMD, "get", path]

      output = PopenWrapper.run(
          cmd,
          path,
          args,
          ignore_exitcode: ignore_exitcode,
          workdir: workdir)

      (output == 0)
    end

    def self.terraform_plan(path: '', workdir: Dir.pwd, args: '', ignore_exitcode: false)
      cmd = [Covalence::TERRAFORM_CMD, "plan"]

      output = PopenWrapper.run(
          cmd,
          path,
          args,
          ignore_exitcode: ignore_exitcode,
          workdir: workdir)

      (output == 0)
    end

    def self.terraform_validate(path, workdir, args: '', ignore_exitcode: false)
      cmd = [Covalence::TERRAFORM_CMD, "validate"]

      output = PopenWrapper.run(
          cmd,
          path,
          args,
          ignore_exitcode: ignore_exitcode,
          workdir: workdir)

      (output == 0)
    end

    def self.terraform_workspace(workspace, path='', args: '', ignore_exitcode: false)
      cmd = [Covalence::TERRAFORM_CMD, "workspace", "new", workspace]

      output = PopenWrapper.run(
        cmd,
        path,
        args,
        ignore_exitcode: ignore_exitcode)

      (output == 0)
    end

    def self.terraform_output(output_var, args: '')
      raise "TODO: implement me"
    end

    def self.terraform_taint(resource_name, args: '')
      raise "TODO: implement me"
    end

    def self.terraform_untaint(resource_name, args: '')
      raise "TODO: implement me"
    end

    def self.logger
      Covalence::LOGGER
    end

    class << self
      private

      # The only args that should be automated are ones that only expect some DIR/PATH as it's only
      # required arg, most other things need a little bit more manual definition.
      def init_terraform_cmds(file)
        definition = YAML.load_file(file)

        definition['commands'].each do |cmd, sub_hash|
          if sub_hash.blank?
            terraform_cmd = "terraform_#{cmd}"

            next if respond_to?(terraform_cmd.to_sym)
            define_singleton_method(terraform_cmd) do |path=Dir.pwd(), args: ''|
              output = PopenWrapper.run([Covalence::TERRAFORM_CMD, cmd], path, args)
              (output == 0)
            end
          elsif sub_hash.is_a?(Hash)
            sub_hash.keys.each do |sub_command|
              terraform_cmd = "terraform_#{cmd}_#{sub_command}"

              next if respond_to?(terraform_cmd.to_sym)
              define_singleton_method(terraform_cmd) do |path=Dir.pwd(), args: ''|
                output = PopenWrapper.run([Covalence::TERRAFORM_CMD, cmd, sub_command], path, args)
                (output == 0)
              end
            end
          else
            raise "Invalid yml context"
          end
        end
      end #init_terraform_cmds
    end #private
  end #TerraformCli
end

Covalence::TerraformCli.require_init
