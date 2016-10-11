module Covalence
  class PackerCli
    class << self
      def require_init()
        cmds_yml = File.expand_path("packer.yml", __dir__)
        init_packer_cmds(cmds_yml)
      end

      private
      def init_packer_cmds(file)
        definition = YAML.load_file(file)

        definition['commands'].each do |cmd, _|
          packer_cmd = "packer_#{cmd}"

          next if respond_to?(packer_cmd.to_sym)
          define_singleton_method(packer_cmd) do |template, args: ''|
            if Covalence::PACKER_IMG.blank?
              output = PopenWrapper.run([Covalence::PACKER_CMD, cmd], template, args)
              (output == 0)
            else
              parent, base = docker_scope_path(template)
              output = PopenWrapper.run([
                Covalence::PACKER_CMD,
                "-v #{parent}:/data -w /data #{Covalence::PACKER_IMG}",
                cmd],
                File.join('/data', base),
                args)
              (output == 0)
            end
          end #define_singleton_method
        end # definition
      end

      # When packer runs inside a container, dir scoping and volume mounts need to be considered.
      # This enforces the standard that packer modules need to be scoped under the WORKSPACE dir module
      # to avoid volume mount problems.
      def docker_scope_path(path)
        if !path.start_with?(Covalence::WORKSPACE)
          raise "cannot target packer module #{path} outside WORKSPACE base path: #{Covalence::WORKSPACE}"
        end
        [Covalence::WORKSPACE, path.sub(Covalence::WORKSPACE, "")]
      end

    end # class << self
  end #PackerCli
end

Covalence::PackerCli.require_init
