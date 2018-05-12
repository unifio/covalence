require 'rake'
require 'consul_loader'
require_relative '../covalence'
require_relative 'core/cli_wrappers/sops_cli'

module Covalence
  class SopsTasks
    extend Rake::DSL

    def self.run
      desc 'Decrypt files in [:path, :extension]'
      task 'sops:decrypt_path', [:path, :extension] do |t, args|
        # should have defaults in just one place but rake isn't a terribly great entrypoint to centralize on
        SopsCli.decrypt_path(args[:path] || SopsCli.default_data_dir,
                             args[:extension] || ".yaml")
      end

      desc 'Encrypt files in [:path, :extension]'
      task 'sops:encrypt_path', [:path, :extension] do |t, args|
        SopsCli.encrypt_path(args[:path] || SopsCli.default_data_dir,
                             args[:extension] || ".yaml")
      end

      desc 'Clean decrypt files in [:path, :extension]'
      task 'sops:clean_decrypt_path', [:path, :extension] do |t, args|
        SopsCli.clean_decrypt_path(args[:path] || SopsCli.default_data_dir,
                                   args[:extension] || "*")
      end
    end
  end
end

Covalence::SopsTasks.run
