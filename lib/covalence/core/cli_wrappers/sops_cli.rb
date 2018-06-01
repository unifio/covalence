require 'semantic'
require 'fileutils'
require 'yaml'
require 'active_support/core_ext/object/blank'

require_relative '../../../covalence'
require_relative 'popen_wrapper'

module Covalence
  class SopsCli

    DIRECTION = {
      encrypt: {
        sops_option: "--encrypt",
        file_search_suffix: "-decrypted",
        file_replace_suffix: "-encrypted"
      },
      decrypt: {
        sops_option: "--decrypt",
        file_search_suffix: "-encrypted",
        file_replace_suffix: "-decrypted"
      }
    }

    def self.encrypt_path(path=default_data_dir, extension=".yaml")
      modify_files(DIRECTION[:encrypt], path, extension)
    end

    def self.decrypt_path(path=default_data_dir, extension=".yaml")
      modify_files(DIRECTION[:decrypt], path, extension)
    end

    # Clean targets all extensions by default, sounds like a more secure way to avoid commiting something accidentally
    def self.clean_decrypt_path(path, extension="*", dry_run: false, verbose: true)
      file_path = File.expand_path(path)

      if File.file?(file_path)
        files = [file_path]
      else
        files = Dir.glob(File.join(file_path, "**" , "*#{DIRECTION[:decrypt][:file_replace_suffix]}#{extension}"))
      end

      unless files.blank?
        FileUtils.rm_f(files, {
          noop: dry_run,
          verbose: verbose
        })
      end
    end

    def self.default_data_dir
      @default_data_dir ||= File.join(WORKSPACE, YAML.load_file(CONFIG).fetch(:yaml, {}).fetch(:datadir, ""))
    end

    class << self
      private

      # Intentionally unified the logic so that encryption and decryption would follow the
      # same path and avoid logic forking
      def modify_files(direction_hash, path, extension=".yaml")
        if Semantic::Version.new(Covalence::SOPS_VERSION) < Semantic::Version.new("3.0.0")
          raise "Sops v3.0.0 or newer required"
        end

        files = []
        file_path = File.expand_path(path)
        cmd = [Covalence::SOPS_CMD, direction_hash[:sops_option]]

        if File.file?(file_path)
          files = [file_path]
        else
          files = Dir.glob(File.join(file_path, "**" , "*#{direction_hash[:file_search_suffix]}#{extension}"))
        end

        files.map do |file|
          dirname, basename =  File.split(file)
          new_file = File.join(dirname, basename.gsub(direction_hash[:file_search_suffix],direction_hash[:file_replace_suffix]))

          break unless (PopenWrapper.run(cmd, file, "> #{new_file}") == 0)
          new_file
        end
      end
    end
  end
end
