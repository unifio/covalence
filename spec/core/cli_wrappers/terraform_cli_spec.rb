require 'fileutils'
require 'tmpdir'
require 'active_support/core_ext/kernel/reporting'

require 'spec_helper'
require_relative File.join(Covalence::GEM_ROOT, 'core/cli_wrappers/terraform_cli')

module Covalence
  RSpec.describe TerraformCli do
    before(:all) do
      @tmp_dir = Dir.mktmpdir
    end
    after(:all) { FileUtils.remove_entry(@tmp_dir) }
    before(:each) do
      allow($stdout).to receive(:write)
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
        expected_args = [ENV.to_h, "terraform apply #{@tmp_dir}"]
        expect(Kernel).to receive(:system).with(*expected_args).and_return(true)
        expect(described_class.terraform_apply(path = @tmp_dir)).to be true
      end

      it "#terraform_destroy" do
        expected_args = [ENV.to_h, "terraform destroy #{@tmp_dir}"]
        expect(Kernel).to receive(:system).with(*expected_args).and_return(true)
        expect(described_class.terraform_destroy(path = @tmp_dir)).to be true
      end

      it "#terraform_fmt" do
        expected_args = [ENV.to_h, "terraform fmt #{@tmp_dir}"]
        expect(Kernel).to receive(:system).with(*expected_args).and_return(true)
        expect(described_class.terraform_fmt(path = @tmp_dir)).to be true
      end

      it "#terraform_get" do
        expected_args = [ENV.to_h, "terraform get #{@tmp_dir}"]
        expect(Kernel).to receive(:system).with(*expected_args).and_return(true)
        expect(described_class.terraform_get(path = @tmp_dir)).to be true
      end

      it "#terraform_graph" do
        expected_args = [ENV.to_h, "terraform graph #{@tmp_dir}"]
        expect(Kernel).to receive(:system).with(*expected_args).and_return(true)
        expect(described_class.terraform_graph(path = @tmp_dir)).to be true
      end

      it "#terraform_plan" do
        expected_args = [ENV.to_h, "terraform plan #{@tmp_dir}"]
        expect(Kernel).to receive(:system).with(*expected_args).and_return(true)
        expect(described_class.terraform_plan(path = @tmp_dir)).to be true
      end

      it "#terraform_push" do
        expected_args = [ENV.to_h, "terraform push #{@tmp_dir}"]
        expect(Kernel).to receive(:system).with(*expected_args).and_return(true)
        expect(described_class.terraform_push(path = @tmp_dir)).to be true
      end

      it "#terraform_refresh" do
        expected_args = [ENV.to_h, "terraform refresh #{@tmp_dir}"]
        expect(Kernel).to receive(:system).with(*expected_args).and_return(true)
        expect(described_class.terraform_refresh(path = @tmp_dir)).to be true
      end

      it "#terraform_remote_config" do
        expected_args = [ENV.to_h, "terraform remote config #{@tmp_dir}"]
        expect(Kernel).to receive(:system).with(*expected_args).and_return(true)
        expect(described_class.terraform_remote_config(path = @tmp_dir)).to be true
      end

      it "#terraform_remote_pull" do
        expected_args = [ENV.to_h, "terraform remote pull #{@tmp_dir}"]
        expect(Kernel).to receive(:system).with(*expected_args).and_return(true)
        expect(described_class.terraform_remote_pull(path = @tmp_dir)).to be true
      end

      it "#terraform_remote_push" do
        expected_args = [ENV.to_h, "terraform remote push #{@tmp_dir}"]
        expect(Kernel).to receive(:system).with(*expected_args).and_return(true)
        expect(described_class.terraform_remote_push(path = @tmp_dir)).to be true
      end

      it "#terraform_show" do
        expected_args = [ENV.to_h, "terraform show #{@tmp_dir}"]
        expect(Kernel).to receive(:system).with(*expected_args).and_return(true)
        expect(described_class.terraform_show(path = @tmp_dir)).to be true
      end

      it "#terraform_validate" do
        expected_args = [ENV.to_h, "terraform validate #{@tmp_dir}"]
        expect(Kernel).to receive(:system).with(*expected_args).and_return(true)
        expect(described_class.terraform_validate(path = @tmp_dir)).to be true
      end

      it "#terraform_version" do
        expected_args = [ENV.to_h, "terraform version #{@tmp_dir}"]
        expect(Kernel).to receive(:system).with(*expected_args).and_return(true)
        expect(described_class.terraform_version(path = @tmp_dir)).to be true
      end

      pending "#terraform_clean"

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

        expected_args = [ENV.to_h, "/usr/local/bin/terraform plan #{@tmp_dir}"]
        expect(Kernel).to receive(:system).with(*expected_args).and_return(true)
        expect(described_class.terraform_plan(path = @tmp_dir)).to be true
      end
    end

    describe "executes terraform commands within a container", if: system('docker info > /dev/null 2>&1') do
      before(:each) do
        ENV['TERRAFORM_IMG'] = "unifio/terraform:latest"
        ENV['TERRAFORM_CMD'] = "docker run -e ATLAS_TOKEN=$ATLAS_TOKEN --rm"
        # force constants to re-init
        Kernel.silence_warnings {
          load File.join(Covalence::GEM_ROOT, '../covalence.rb')
        }
      end

      it "#terraform_plan" do
        parent, base = Pathname.new(@tmp_dir).split
        expected_args = [ENV.to_h, "#{ENV['TERRAFORM_CMD']} -v #{parent}:/data -w /data/#{base} #{ENV['TERRAFORM_IMG']} plan"]
        expect(Kernel).to receive(:system).with(*expected_args).and_return(true)
        expect(described_class.terraform_plan(path = @tmp_dir)).to be true
      end

      it "#terraform_check_style" do
        parent, base = Pathname.new(@tmp_dir).split
        expected_args = [ENV, "#{ENV['TERRAFORM_CMD']} -v #{parent}:/data -w /data/#{base} #{ENV['TERRAFORM_IMG']} fmt -write=false"]
        process_double = double("process_status")
        allow(process_double).to receive(:success?).and_return(true)
        expect(Open3).to receive(:capture2e).with(*expected_args).and_return(["", process_double])
        expect(described_class.terraform_check_style(path = @tmp_dir)).to be true
      end
    end

    pending "cleans up existing state data from the given stack directory"
    #@cmd_test = Terraform::Stack.new(@stack_dir, dir: @parent_dir, env: "", img: "", cmd: "", stub: "false")
    #cmd = "/bin/sh -c \"rm -fr .terraform *.tfstate*\""
    #expect(Rake).to receive(:sh).with(cmd).and_return(true)
    #@cmd_test.clean

    #it "cleans up existing state data from the given stack directory within a container" do
    # unnecesary, this was roundabout way to clean the files.
    #@cmd_test = Terraform::Stack.new(@stack_dir, dir: @parent_dir, env: "", img: "unifio/terraform:latest", cmd: "docker run --rm", stub: "false")
    #cmd = "docker run --rm -v #{@parent_dir}:/data -w /data/#{@stack_dir} --entrypoint=\"/bin/sh\" unifio/terraform:latest -c \"rm -fr .terraform *.tfstate*\""
    #expect(Rake).to receive(:sh).with(cmd).and_return(true)
    #@cmd_test.clean
    #end
  end
end
