require 'fileutils'
require 'tmpdir'
require 'active_support/core_ext/kernel/reporting'

require 'spec_helper'
require_relative File.join(Covalence::GEM_ROOT, 'core/cli_wrappers/packer_cli')
require_relative File.join(Covalence::GEM_ROOT, 'core/cli_wrappers/popen_wrapper')

module Covalence
  RSpec.describe PackerCli do
    before(:all) { @tmp_dir = Dir.mktmpdir }
    after(:all) { FileUtils.remove_entry(@tmp_dir) }

    before(:each) do
      @cached_env = {}
      %w(PACKER_IMG PACKER_CMD COVALENCE_WORKSPACE COVALENCE_PACKER_DIR).each do |env_var|
        @cached_env[env_var] = ENV[env_var]
      end
      allow(PopenWrapper).to receive(:print_cmd_string)

      ENV['PACKER_IMG'] = ""
      ENV['PACKER_CMD'] = "packer"
      # force constants to re-init
      Kernel.silence_warnings {
        load File.join(Covalence::GEM_ROOT, '../covalence.rb')
      }
    end

    after(:each) do
      %w(PACKER_IMG PACKER_CMD COVALENCE_WORKSPACE COVALENCE_PACKER_DIR).each do |env_var|
        ENV[env_var] = @cached_env[env_var]
      end
      Kernel.silence_warnings {
        load File.join(Covalence::GEM_ROOT, '../covalence.rb')
      }
    end

    it "#packer_build" do
      expected_args = [ENV, "packer build #{@tmp_dir}", anything]
      expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(0)
      expect(described_class.packer_build(@tmp_dir)).to be true
    end

    it "#packer_fix" do
      expected_args = [ENV, "packer fix #{@tmp_dir}", anything]
      expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(0)
      expect(described_class.packer_fix(@tmp_dir)).to be true
    end

    it "#packer_inspect" do
      expected_args = [ENV, "packer inspect #{@tmp_dir}", anything]
      expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(0)
      expect(described_class.packer_inspect(@tmp_dir)).to be true
    end

    it "#packer_push" do
      expected_args = [ENV, "packer push #{@tmp_dir}", anything]
      expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(0)
      expect(described_class.packer_push(@tmp_dir)).to be true
    end

    it "#packer_validate" do
      expected_args = [ENV, "packer validate #{@tmp_dir}", anything]
      expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(0)
      expect(described_class.packer_validate(@tmp_dir)).to be true
    end

    it "#packer_version" do
      expected_args = [ENV, "packer version #{@tmp_dir}", anything]
      expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(0)
      expect(described_class.packer_version(@tmp_dir)).to be true
    end
  end
end
