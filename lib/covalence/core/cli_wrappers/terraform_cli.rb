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
      if Semantic::Version.new(Covalence::TERRAFORM_VERSION) >= Semantic::Version.new("0.7.0")
        cmds_yml = File.expand_path("terraform.yml", __dir__)
      else
        cmds_yml = File.expand_path("terraform-0.6.16.yml", __dir__)
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
      if Covalence::TF_IMG.blank?
        output, status = Open3.capture2e(ENV, Covalence::TF_CMD, "fmt", "-write=false", path)
      else
        output, status = Open3.capture2e(ENV, "#{Covalence::TF_CMD} -v #{path}:/path -w /path #{Covalence::TF_IMG} fmt -write=false")
      end
      return false unless status.success?
      output = output.split("\n")
      (output.size == 0)
    end

    def self.terraform_remote_config(path=Dir.pwd(), args: '')
      if Covalence::TF_IMG.blank?
        PopenWrapper.run([Covalence::TF_CMD, "remote", "config"], path, args)
      else
        PopenWrapper.run([Covalence::TF_CMD, "-v #{path}:/path -w /path #{Covalence::TF_IMG}", "remote", "config"], '', args)
      end
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
              if Covalence::TF_IMG.blank?
                PopenWrapper.run([Covalence::TF_CMD, cmd], path, args)
              else
                parent, base = docker_scope_path(path)
                PopenWrapper.run([Covalence::TF_CMD, "-v #{parent}:/tf_base -w #{File.join('/tf_base', base)} #{Covalence::TF_IMG}", cmd], '', args)
              end
            end
          elsif sub_hash.is_a?(Hash)
            sub_hash.keys.each do |sub_command|
              terraform_cmd = "terraform_#{cmd}_#{sub_command}"

              next if respond_to?(terraform_cmd.to_sym)
              define_singleton_method(terraform_cmd) do |path=Dir.pwd(), args: ''|
                if Covalence::TF_IMG.blank?
                  PopenWrapper.run([Covalence::TF_CMD, cmd, sub_command], path, args)
                else
                  parent, base = docker_scope_path(path)
                  PopenWrapper.run([Covalence::TF_CMD, "-v #{parent}:/tf_base -w #{File.join('/tf_base', base)} #{Covalence::TF_IMG}", cmd, sub_command], '', args)
                end
              end
            end
          else
            raise "Invalid yml context"
          end
        end
      end #init_terraform_cmds

      # When terraform runs inside a container, dir scoping and volume mounts need to be considered.
      # This enforces the standard that terraform modules need to be scoped under the TERRAFORM dir module
      # to avoid volume mount problems.
      def docker_scope_path(path)
        if !path.start_with?(TERRAFORM)
          raise "cannot target terraform module #{path} outside TERRAFORM base path: #{TERRAFORM}"
        end
        [TERRAFORM, path.sub(TERRAFORM, "")]
      end
    end #private
  end #TerraformCli
end

Covalence::TerraformCli.require_init
