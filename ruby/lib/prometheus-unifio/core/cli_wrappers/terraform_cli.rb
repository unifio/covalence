require 'yaml'
require 'fileutils'
require 'tmpdir'
require 'active_support/core_ext/object/blank'
require 'open3'

require_relative '../../../prometheus-unifio'
require_relative 'popen_wrapper'

module PrometheusUnifio
  class TerraformCli
    def self.require_init()
      if Semantic::Version.new(PrometheusUnifio::TERRAFORM_VERSION) >= Semantic::Version.new("0.7.0")
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
      if PrometheusUnifio::TF_IMG.blank?
        output, status = Open3.capture2e(ENV, PrometheusUnifio::TF_CMD, "fmt", "-write=false", path)
      else
        parent, base = Pathname.new(path).split
        output, status = Open3.capture2e(ENV, "#{PrometheusUnifio::TF_CMD} -v #{parent}:/data -w /data/#{base} #{PrometheusUnifio::TF_IMG} fmt -write=false")
      end
      return false unless status.success?
      output = output.split("\n")
      (output.size == 0)
    end

    def self.terraform_output(output_var, args='')
      raise "TODO: implement me"
    end

    def self.terraform_taint(resource_name, args='')
      raise "TODO: implement me"
    end

    def self.terraform_untaint(resource_name, args='')
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
              if PrometheusUnifio::TF_IMG.blank?
                PopenWrapper.run([PrometheusUnifio::TF_CMD, cmd], path, args)
              else
                parent, base = Pathname.new(path).split
                PopenWrapper.run([PrometheusUnifio::TF_CMD, "-v #{parent}:/data -w /data/#{base} #{PrometheusUnifio::TF_IMG}", cmd], '', args)
              end
            end
          elsif sub_hash.is_a?(Hash)
            sub_hash.keys.each do |sub_command|
              terraform_cmd = "terraform_#{cmd}_#{sub_command}"

              next if respond_to?(terraform_cmd.to_sym)
              define_singleton_method(terraform_cmd) do |path=Dir.pwd(), args: ''|
                if PrometheusUnifio::TF_IMG.blank?
                  PopenWrapper.run([PrometheusUnifio::TF_CMD, cmd, sub_command], path, args)
                else
                  parent, base = Pathname.new(path).split
                  PopenWrapper.run([PrometheusUnifio::TF_CMD, "-v #{parent}:/data -w /data/#{base} #{PrometheusUnifio::TF_IMG}", cmd, sub_command], '', args)
                end
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

PrometheusUnifio::TerraformCli.require_init
