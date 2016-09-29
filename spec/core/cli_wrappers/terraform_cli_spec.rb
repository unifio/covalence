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
      %w(TERRAFORM_IMG TERRAFORM_CMD COVALENCE_WORKSPACE COVALENCE_TERRAFORM_DIR).each do |env_var|
        @cached_env[env_var] = ENV[env_var]
      end
      allow(PopenWrapper).to receive(:print_cmd_string)
    end

    after(:each) do
      %w(TERRAFORM_IMG TERRAFORM_CMD COVALENCE_WORKSPACE COVALENCE_TERRAFORM_DIR).each do |env_var|
        ENV[env_var] = @cached_env[env_var]
      end
      Kernel.silence_warnings {
        load File.join(Covalence::GEM_ROOT, '../covalence.rb')
      }
    end

    describe "when running native terraform", :native do
      before(:each) do
        ENV['TERRAFORM_IMG'] = ""
        ENV['TERRAFORM_CMD'] = "terraform"
        # force constants to re-init
        Kernel.silence_warnings {
          load File.join(Covalence::GEM_ROOT, '../covalence.rb')
        }
      end

      it "#terraform_apply" do
        expected_args = [ENV, "terraform apply #{@tmp_dir}", anything]
        expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(true)
        expect(described_class.terraform_apply(path = @tmp_dir)).to be true
      end

      it "#terraform_destroy" do
        expected_args = [ENV, "terraform destroy #{@tmp_dir}", anything]
        expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(true)
        expect(described_class.terraform_destroy(path = @tmp_dir)).to be true
      end

      it "#terraform_fmt" do
        expected_args = [ENV, "terraform fmt #{@tmp_dir}", anything]
        expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(true)
        expect(described_class.terraform_fmt(path = @tmp_dir)).to be true
      end

      it "#terraform_get" do
        expected_args = [ENV, "terraform get #{@tmp_dir}", anything]
        expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(true)
        expect(described_class.terraform_get(path = @tmp_dir)).to be true
      end

      it "#terraform_graph" do
        expected_args = [ENV, "terraform graph #{@tmp_dir}", anything]
        expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(true)
        expect(described_class.terraform_graph(path = @tmp_dir)).to be true
      end

      it "#terraform_plan" do
        expected_args = [ENV, "terraform plan #{@tmp_dir}", anything]
        expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(true)
        expect(described_class.terraform_plan(path = @tmp_dir)).to be true
      end

      it "#terraform_push" do
        expected_args = [ENV, "terraform push #{@tmp_dir}", anything]
        expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(true)
        expect(described_class.terraform_push(path = @tmp_dir)).to be true
      end

      it "#terraform_refresh" do
        expected_args = [ENV, "terraform refresh #{@tmp_dir}", anything]
        expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(true)
        expect(described_class.terraform_refresh(path = @tmp_dir)).to be true
      end

      it "#terraform_remote_config" do
        expected_args = [ENV, "terraform remote config #{@tmp_dir}", anything]
        expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(true)
        expect(described_class.terraform_remote_config(path = @tmp_dir)).to be true
      end

      it "#terraform_remote_pull" do
        expected_args = [ENV, "terraform remote pull #{@tmp_dir}", anything]
        expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(true)
        expect(described_class.terraform_remote_pull(path = @tmp_dir)).to be true
      end

      it "#terraform_remote_push" do
        expected_args = [ENV, "terraform remote push #{@tmp_dir}", anything]
        expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(true)
        expect(described_class.terraform_remote_push(path = @tmp_dir)).to be true
      end

      it "#terraform_show" do
        expected_args = [ENV, "terraform show #{@tmp_dir}", anything]
        expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(true)
        expect(described_class.terraform_show(path = @tmp_dir)).to be true
      end

      it "#terraform_validate" do
        expected_args = [ENV, "terraform validate #{@tmp_dir}", anything]
        expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(true)
        expect(described_class.terraform_validate(path = @tmp_dir)).to be true
      end

      it "#terraform_version" do
        expected_args = [ENV, "terraform version #{@tmp_dir}", anything]
        expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(true)
        expect(described_class.terraform_version(path = @tmp_dir)).to be true
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
        expect(Open3).to receive(:capture2e).with(*expected_args).and_return(["", process_double])
        expect(described_class.terraform_check_style(path = @tmp_dir)).to be true
      end

      it "executes terraform commands with custom settings" do
        ENV['TERRAFORM_CMD'] = "/usr/local/bin/terraform"
        # force constants to re-init
        Kernel.silence_warnings {
          # swallow all rescue from non-existant terraform binary above.
          load File.join(Covalence::GEM_ROOT, '../covalence.rb') rescue nil
        }

        expected_args = [ENV, "/usr/local/bin/terraform plan #{@tmp_dir}", anything]
        expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(true)
        expect(described_class.terraform_plan(path = @tmp_dir)).to be true
      end
    end

    describe "executes terraform commands within a container", if: system('docker info > /dev/null 2>&1') do
      before(:each) do
        ENV['TERRAFORM_IMG'] = "unifio/terraform:latest"
        ENV['TERRAFORM_CMD'] = "docker run -e ATLAS_TOKEN=$ATLAS_TOKEN --rm"
        # should probably figure out a way to ensure tmp dir created is deep enough
        @tmp_dir_array = Pathname.new(@tmp_dir).each_filename.to_a
        ENV['COVALENCE_WORKSPACE'] = File::SEPARATOR + @tmp_dir_array[0,1].join(File::SEPARATOR)
        ENV['COVALENCE_TERRAFORM_DIR'] = @tmp_dir_array[1]
        # force constants to re-init
        Kernel.silence_warnings {
          load File.join(Covalence::GEM_ROOT, '../covalence.rb')
        }
      end

      it "#terraform_plan" do
        expected_args = [ENV, "#{ENV['TERRAFORM_CMD']} -v #{TERRAFORM}:/tf_base -w #{File.join('/tf_base/', @tmp_dir_array[2..-1].join(File::SEPARATOR))} #{ENV['TERRAFORM_IMG']} plan", anything]
        expect(PopenWrapper).to receive(:spawn_subprocess).with(*expected_args).and_return(true)
        expect(described_class.terraform_plan(path = @tmp_dir)).to be true
      end

      it "#terraform_check_style" do
        expected_args = [ENV, "#{ENV['TERRAFORM_CMD']} -v #{@tmp_dir}:/path -w /path #{ENV['TERRAFORM_IMG']} fmt -write=false"]
        process_double = double("process_status")
        allow(process_double).to receive(:success?).and_return(true)
        expect(Open3).to receive(:capture2e).with(*expected_args).and_return(["", process_double])
        expect(described_class.terraform_check_style(path = @tmp_dir)).to be true
      end
    end
  end
end
