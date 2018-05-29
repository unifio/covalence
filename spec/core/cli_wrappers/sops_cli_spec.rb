require 'fileutils'
require 'tmpdir'

require 'spec_helper'
require_relative File.join(Covalence::GEM_ROOT, 'core/cli_wrappers/sops_cli')
require_relative File.join(Covalence::GEM_ROOT, 'core/cli_wrappers/popen_wrapper')

module Covalence
  RSpec.describe SopsCli do
    before(:each) do
      @tmp_dir = Dir.mktmpdir

    end

    after(:each) do
      FileUtils.remove_entry(@tmp_dir)
    end

    it "#encrypt_path on default file extensions" do
      FileUtils.touch(File.join(@tmp_dir, "yaml_file-decrypted.yaml"))
      FileUtils.touch(File.join(@tmp_dir, "json_file-decrypted.json"))
      cmd = [Covalence::SOPS_CMD, Covalence::SopsCli::DIRECTION[:encrypt][:sops_option]]
      expect(PopenWrapper).to receive(:run).with(cmd, File.join(@tmp_dir, "yaml_file-decrypted.yaml"), anything).and_return(0)
      expect(PopenWrapper).to_not receive(:run).with(cmd, File.join(@tmp_dir, "json_file-decrypted.json"), anything)

      described_class.encrypt_path(@tmp_dir)
    end

    it "#encrypt_path on all file extensions" do
      FileUtils.touch(File.join(@tmp_dir, "yaml_file-decrypted.yaml"))
      FileUtils.touch(File.join(@tmp_dir, "json_file-decrypted.json"))
      FileUtils.touch(File.join(@tmp_dir, "rando_file-decrypted"))
      cmd = [Covalence::SOPS_CMD, Covalence::SopsCli::DIRECTION[:encrypt][:sops_option]]
      %w(yaml_file-decrypted.yaml json_file-decrypted.json rando_file-decrypted).each do |fn|
        expect(PopenWrapper).to receive(:run).with(cmd, File.join(@tmp_dir, fn), anything).and_return(0)
      end

      described_class.encrypt_path(@tmp_dir, "*")
    end

    it "#encrypt_path on specific file" do
      FileUtils.touch(File.join(@tmp_dir, "some_random_file"))
      cmd = [Covalence::SOPS_CMD, Covalence::SopsCli::DIRECTION[:encrypt][:sops_option]]

      expect(PopenWrapper).to receive(:run).with(cmd, File.join(@tmp_dir, "some_random_file"), anything).and_return(0)
      described_class.encrypt_path(File.join(@tmp_dir, "some_random_file"))
    end

    it "#decrypt_path on default file extensions" do
      FileUtils.touch(File.join(@tmp_dir, "yaml_file-encrypted.yaml"))
      FileUtils.touch(File.join(@tmp_dir, "json_file-encrypted.json"))
      cmd = [Covalence::SOPS_CMD, Covalence::SopsCli::DIRECTION[:decrypt][:sops_option]]
      expect(PopenWrapper).to receive(:run).with(cmd, File.join(@tmp_dir, "yaml_file-encrypted.yaml"), anything).and_return(0)
      expect(PopenWrapper).to_not receive(:run).with(cmd, File.join(@tmp_dir, "json_file-encrypted.json"), anything)

      described_class.decrypt_path(@tmp_dir)
    end

    it "#clean_decrypt_path" do
      FileUtils.touch(File.join(@tmp_dir, "yaml_file-decrypted.yaml"))
      FileUtils.touch(File.join(@tmp_dir, "json_file-decrypted.json"))
      FileUtils.touch(File.join(@tmp_dir, "random_file"))
      FileUtils.touch(File.join(@tmp_dir, "random_file-decrypted"))
      FileUtils.touch(File.join(@tmp_dir, "json_file-encrypted.json"))

      expect(Dir[File.join(@tmp_dir, "*")].length).to eq(5)
      described_class.clean_decrypt_path(@tmp_dir, verbose: false)
      expect(Dir[File.join(@tmp_dir, "*")].length).to eq(2)
      expect(Dir[File.join(@tmp_dir, "*")].map{|f| File.basename(f)}).to include("random_file", "json_file-encrypted.json")
    end
  end
end
