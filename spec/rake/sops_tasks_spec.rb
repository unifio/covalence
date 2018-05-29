require 'spec_helper'
require 'fileutils'

require_relative File.join(Covalence::GEM_ROOT, 'sops_tasks')
require_relative File.join(Covalence::GEM_ROOT, 'core/cli_wrappers/popen_wrapper')
require_relative '../shared_contexts/rake.rb'


module Covalence
  describe SopsTasks do
    let(:task_files) { 'sops_tasks.rb' }

    describe "sops:decrypt_path" do
      include_context "rake"

      it "sops:decrypt_path decrypts *.yaml files in the data directory by default" do
        cmd = [Covalence::SOPS_CMD, Covalence::SopsCli::DIRECTION[:decrypt][:sops_option]]

        expect(PopenWrapper).to receive(:run).with(cmd, File.expand_path("./spec/fixtures/data/secure/contexts/example-myapp-encrypted.yaml"), anything).and_return(0)
        Rake::Task["sops:decrypt_path"].invoke
      end

      it "sops:decrypt_path decrypts specific file" do
        cmd = [Covalence::SOPS_CMD, Covalence::SopsCli::DIRECTION[:decrypt][:sops_option]]

        expect(PopenWrapper).to receive(:run).with(cmd, File.expand_path("./spec/fixtures/data/consul-kv.yml"), anything).and_return(0)
        Rake::Task["sops:decrypt_path"].invoke("spec/fixtures/data/consul-kv.yml")
      end

      it "sops:encrypt_path encrypts *.yaml files in the data directory by default" do
        expect(PopenWrapper).to_not receive(:run)
        # there's no -decrypted.yaml files in the data path
        Rake::Task["sops:encrypt_path"].invoke
      end

      it "sops:clean_decrypt_path should remove -decrypted* files in the data directory" do
        expect(FileUtils).to_not receive(:rm_f)
        # there's no -decrypted.yaml files in the data path
        Rake::Task["sops:clean_decrypt_path"].invoke
      end
    end
  end
end
