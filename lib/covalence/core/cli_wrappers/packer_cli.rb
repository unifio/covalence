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
            PopenWrapper.run([Covalence::PACKER_CMD, cmd], template, args)#, dry_run: true)
          end
        end
      end
    end
  end
end

Covalence::PackerCli.require_init
