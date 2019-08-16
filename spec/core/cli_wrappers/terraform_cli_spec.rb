require 'fileutils'
require 'tmpdir'
require 'active_support/core_ext/kernel/reporting'

require 'spec_helper'
require_relative File.join(Covalence::GEM_ROOT, 'core/cli_wrappers/terraform_cli')
require_relative File.join(Covalence::GEM_ROOT, 'core/cli_wrappers/popen_wrapper')

module Covalence
  RSpec.describe TerraformCli do
    before(:all) { @tmp_dir = Dir.mktmpdir }
    after(:all) { FileUtils.remove_entry(@tmp_dir) }

    before(:each) do
      @cached_env = {}
      %w(TERRAFORM_CMD COVALENCE_WORKSPACE COVALENCE_TERRAFORM_DIR).each do |env_var|
        @cached_env[env_var] = ENV[env_var]
      end
      allow(PopenWrapper).to receive(:print_cmd_string)

      ENV['TERRAFORM_CMD'] = "terraform"
      # force constants to re-init
      Kernel.silence_warnings {
        load File.join(Covalence::GEM_ROOT, '../covalence.rb')
      }
    end

    after(:each) do
      %w(TERRAFORM_CMD COVALENCE_WORKSPACE COVALENCE_TERRAFORM_DIR).each do |env_var|
        ENV[env_var] = @cached_env[env_var]
      end
      Kernel.silence_warnings {
        load File.join(Covalence::GEM_ROOT, '../covalence.rb')
      }
    end

    it "#terraform_apply" do
      expected_args = [ENV, "terraform apply #{@tmp_dir}", anything]
      expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(0)
      expect(described_class.terraform_apply(@tmp_dir)).to be true
    end

    it "#terraform_destroy" do
      expected_args = [ENV, "terraform destroy #{@tmp_dir}", anything]
      expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(0)
      expect(described_class.terraform_destroy(@tmp_dir)).to be true
    end

    it "#terraform_fmt" do
      expected_args = [ENV, "terraform fmt #{@tmp_dir}", anything]
      expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(0)
      expect(described_class.terraform_fmt(@tmp_dir)).to be true
    end

    it "#terraform_get" do
      expected_args = [ENV, "terraform get #{@tmp_dir}", anything]
      expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(0)
      expect(described_class.terraform_get(@tmp_dir)).to be true
    end

    it "#terraform_graph" do
      expected_args = [ENV, "terraform graph #{@tmp_dir}", anything]
      expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(0)
      expect(described_class.terraform_graph(@tmp_dir)).to be true
    end

    it "#terraform_init" do
      expected_args = [ENV, "terraform init -get-plugins=false -get=false -input=false", anything]
      expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(0)
      expect(described_class.terraform_init(workdir: @tmp_dir)).to be true
    end

    it "#terraform_plan" do
      expected_args = [ENV, "terraform plan", anything]
      expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(0)
      expect(described_class.terraform_plan(workdir: @tmp_dir)).to be true
    end

    it "#terraform_push" do
      expected_args = [ENV, "terraform push #{@tmp_dir}", anything]
      expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(0)
      expect(described_class.terraform_push(@tmp_dir)).to be true
    end

    it "#terraform_refresh" do
      expected_args = [ENV, "terraform refresh #{@tmp_dir}", anything]
      expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(0)
      expect(described_class.terraform_refresh(@tmp_dir)).to be true
    end

    it "#terraform_show" do
      expected_args = [ENV, "terraform show #{@tmp_dir}", anything]
      expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(0)
      expect(described_class.terraform_show(@tmp_dir)).to be true
    end

    it "#terraform_validate" do
      expected_args = [ENV, "terraform validate", anything]
      expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(0)
      expect(described_class.terraform_validate(path=@tmp_dir, workdir=@tmp_dir)).to be true
    end

    it "#terraform_version" do
      expected_args = [ENV, "terraform version #{@tmp_dir}", anything]
      expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(0)
      expect(described_class.terraform_version(@tmp_dir)).to be true
    end

    it "#terraform_workspace" do
      expected_args = [ENV, "terraform workspace new example ", anything] ## yea...need that space the `prefix` will be right next to the command
      expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(0)
      expect(described_class.terraform_workspace('example')).to be true
    end

    it "#terraform_clean" do
      Dir.mktmpdir do |dir|
        FileUtils.touch(File.join(dir, 'foo.tfstate'))
        FileUtils.touch(File.join(dir, 'should_ignore.me'))
        Dir.mkdir(File.join(dir, '.terraform'))
        FileUtils.touch(File.join(dir, '.terraform', 'foo.tf'))
        expect((Dir.entries(dir) - %w(. ..)).size).to eq(3)

        described_class.terraform_clean(dir, verbose: false)
        expect((Dir.entries(dir) - %w(. ..)).size).to eq(1)
        expect(File.exist?(File.join(dir, 'should_ignore.me'))).to be true
      end
    end

    it "#terraform_check_style" do
      expected_args = [ENV, "terraform", "fmt", "-write=false", @tmp_dir]
      process_double = double("process_status")
      allow(process_double).to receive(:success?).and_return(true)
      ##expect(Open3).to receive(:capture2e).with(*expected_args).and_return(["", process_double])
      expect(described_class.terraform_check_style(@tmp_dir)).to be true
    end

    it "executes terraform commands with custom settings" do
      ENV['TERRAFORM_CMD'] = "/usr/local/bin/terraform"
      # force constants to re-init
      Kernel.silence_warnings {
        # swallow all rescue from non-existant terraform binary above.
        load File.join(Covalence::GEM_ROOT, '../covalence.rb') rescue nil
      }

      expected_args = [ENV, "/usr/local/bin/terraform plan", anything]
      expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(0)
      expect(described_class.terraform_plan(workdir: @tmp_dir)).to be true
    end
  end
end
