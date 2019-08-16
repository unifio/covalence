require 'spec_helper'
require 'active_support/core_ext/kernel/reporting'

require_relative File.join(Covalence::GEM_ROOT, 'core/cli_wrappers/terraform_cli')
require_relative File.join(Covalence::GEM_ROOT, 'core/cli_wrappers/popen_wrapper')
require_relative File.join(Covalence::GEM_ROOT, 'environment_tasks')
require_relative '../shared_contexts/rake.rb'

module Covalence
  describe EnvironmentTasks do
    let(:task_files) { 'environment_tasks.rb' }
    let(:state_file) { 'state.tf' }

    before(:each) do
      Kernel.silence_warnings {
        Covalence::TERRAFORM_VERSION = "0.9.0"
      }
      allow(PopenWrapper).to receive(:run).and_return(true)
      # suppress FileUtils verbose
      allow($stderr).to receive(:write)
      ARGV.clear
    end

    describe "example:myapp:clean" do
      include_context "rake"

      it "cleans the workspace" do
        expect(TerraformCli).to receive(:terraform_clean)
        subject.invoke
      end
    end

    describe "example:myapp:format" do
      include_context "rake"

      it "formats the workspace" do
        expect(TerraformCli).to receive(:terraform_fmt)
        subject.invoke
      end
    end

    describe "example:myapp:refresh" do
      include_context "rake"

      it "sources modules" do
        expect(TerraformCli).to receive(:terraform_get)
        subject.invoke
      end

      it "initializes the workspace" do
        expect(TerraformCli).to receive(:terraform_init)
        subject.invoke
      end

      it "refreshes the workspace" do
        expect(TerraformCli).to receive(:terraform_refresh)
        subject.invoke
      end
    end

=begin
    describe "example:myapp:verify" do
      include_context "rake"

      it "sources modules" do
        expect(TerraformCli).to receive(:terraform_get)
        subject.invoke
      end

      it "initializes the workspace" do
        expect(TerraformCli).to receive(:terraform_init)
        subject.invoke
      end

      it "generates an inputs varfile" do
        buffer = StringIO.new()
        filename = 'covalence-inputs.tfvars'
        content = <<-CONF
label = "test"
list_test_simple = [
  "foo",
  "bar",
]
map_test_simple = {
  "foo" = "bar"
  "bar" = "foo"
}
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "executes template validation" do
        expect(TerraformCli).to receive(:terraform_validate).with(hash_including(args: array_including(
          "-var-file=covalence-inputs.tfvars"
        )))
        subject.invoke
      end

      it "executes a plan" do
        expect(TerraformCli).to receive(:terraform_plan).with(hash_including(args: array_including(
          "-input=false",
          "-no-color",
          "-var-file=covalence-inputs.tfvars"
        )))
        subject.invoke
      end
    end

    describe "example:myapp:az0:plan" do
      include_context "rake"

      it "generates a state configuration" do
        buffer = StringIO.new()
        filename = 'covalence-state.tf'
        content = <<-CONF
terraform {
  backend "atlas" {
    name = "example/myapp"
  }
}
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "sources modules" do
        expect(TerraformCli).to receive(:terraform_get)
        subject.invoke
      end

      it "initializes the workspace" do
        expect(TerraformCli).to receive(:terraform_init)
        subject.invoke
      end

      it "generates an inputs varfile" do
        buffer = StringIO.new()
        filename = 'covalence-inputs.tfvars'
        content = <<-CONF
label = "test"
list_test_simple = [
  "foo",
  "bar",
]
map_test_simple = {
  "foo" = "bar"
  "bar" = "foo"
}
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "executes a plan" do
        expect(TerraformCli).to receive(:terraform_plan).with(hash_including(args: array_including(
          "-input=false",
          "-no-color",
          "-target=\"module.az0\"",
          "-var-file=covalence-inputs.tfvars"
        )))
        subject.invoke
      end

      context "--no-drift custom arg" do
        before(:each) { ARGV.concat(%w(noop noop -detailed-exitcode)) }

        it "executes a plan with -detailed-exitcode" do
          expect(TerraformCli).to receive(:terraform_init)
          expect(TerraformCli).to receive(:terraform_plan).with(hash_including(args: array_including(
            "-input=false",
            "-no-color",
            "-target=\"module.az0\"",
            "-detailed-exitcode",
            "-var-file=covalence-inputs.tfvars"
          )))
          Rake::Task['example:myapp:az0:plan'].invoke
        end
      end


      context "-some-passthrough-arg" do
        before(:each) { ARGV.concat(%w(noop noop -some-passthrough-arg)) }

        it "executes a plan with -detailed-exitcode" do
          expect(TerraformCli).to receive(:terraform_init)
          expect(TerraformCli).to receive(:terraform_plan).with(hash_including(args: array_including(
            "-input=false",
            "-no-color",
            "-target=\"module.az0\"",
            "-some-passthrough-arg",
            "-var-file=covalence-inputs.tfvars"
          )))
          Rake::Task['example:myapp:az0:plan'].invoke
        end
      end
    end

    describe "example:myapp:az0:plan_destroy" do
      include_context "rake"

      it "generates a state configuration" do
        buffer = StringIO.new()
        filename = 'covalence-state.tf'
        content = <<-CONF
terraform {
  backend "atlas" {
    name = "example/myapp"
  }
}
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "sources modules" do
        expect(TerraformCli).to receive(:terraform_get)
        subject.invoke
      end

      it "initializes the workspace" do
        expect(TerraformCli).to receive(:terraform_init)
        subject.invoke
      end

      it "generates an inputs varfile" do
        buffer = StringIO.new()
        filename = 'covalence-inputs.tfvars'
        content = <<-CONF
label = "test"
list_test_simple = [
  "foo",
  "bar",
]
map_test_simple = {
  "foo" = "bar"
  "bar" = "foo"
}
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "executes a plan" do
        expect(TerraformCli).to receive(:terraform_plan).with(hash_including(args: array_including(
          "-destroy",
          "-input=false",
          "-no-color",
          "-target=\"module.az0\"",
          "-var-file=covalence-inputs.tfvars"
        )))
        subject.invoke
      end
    end

    describe "example:myapp:az0:apply" do
      include_context "rake"

      it "generates a state configuration" do
        buffer = StringIO.new()
        filename = 'covalence-state.tf'
        content = <<-CONF
terraform {
  backend "atlas" {
    name = "example/myapp"
  }
}
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "sources modules" do
        expect(TerraformCli).to receive(:terraform_get)
        subject.invoke
      end

      it "initializes the workspace" do
        expect(TerraformCli).to receive(:terraform_init)
        subject.invoke
      end

      it "generates an inputs varfile" do
        buffer = StringIO.new()
        filename = 'covalence-inputs.tfvars'
        content = <<-CONF
label = "test"
list_test_simple = [
  "foo",
  "bar",
]
map_test_simple = {
  "foo" = "bar"
  "bar" = "foo"
}
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "executes an apply" do
        expect(TerraformCli).to receive(:terraform_apply).with(hash_including(args: array_including(
          "-input=false",
          "-auto-approve=true",
          "-no-color",
          "-target=\"module.az0\"",
          "-var-file=covalence-inputs.tfvars"
        )))
        subject.invoke
      end
    end

    describe "example:myapp:az0:destroy" do
      include_context "rake"

      it "generates a state configuration" do
        buffer = StringIO.new()
        filename = 'covalence-state.tf'
        content = <<-CONF
terraform {
  backend "atlas" {
    name = "example/myapp"
  }
}
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "sources modules" do
        expect(TerraformCli).to receive(:terraform_get)
        subject.invoke
      end

      it "initializes the workspace" do
        expect(TerraformCli).to receive(:terraform_init)
        subject.invoke
      end

      it "generates an inputs varfile" do
        buffer = StringIO.new()
        filename = 'covalence-inputs.tfvars'
        content = <<-CONF
label = "test"
list_test_simple = [
  "foo",
  "bar",
]
map_test_simple = {
  "foo" = "bar"
  "bar" = "foo"
}
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "executes a destroy" do
        expect(TerraformCli).to receive(:terraform_destroy).with(hash_including(args: array_including(
          "-input=false",
          "-no-color",
          "-target=\"module.az0\"",
          "-auto-approve=true",
          "-var-file=covalence-inputs.tfvars"
        )))
        subject.invoke
      end
    end

    describe "example:myapp:az1:plan" do
      include_context "rake"

      it "generates a state configuration" do
        buffer = StringIO.new()
        filename = 'covalence-state.tf'
        content = <<-CONF
terraform {
  backend "atlas" {
    name = "example/myapp"
  }
}
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "sources modules" do
        expect(TerraformCli).to receive(:terraform_get)
        subject.invoke
      end

      it "initializes the workspace" do
        expect(TerraformCli).to receive(:terraform_init)
        subject.invoke
      end

      it "generates an inputs varfile" do
        buffer = StringIO.new()
        filename = 'covalence-inputs.tfvars'
        content = <<-CONF
label = "test"
list_test_simple = [
  "foo",
  "bar",
]
map_test_simple = {
  "foo" = "bar"
  "bar" = "foo"
}
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "executes a plan" do
        expect(TerraformCli).to receive(:terraform_plan).with(hash_including(args: array_including(
          "-input=false",
          "-no-color",
          "-target=\"module.az1\"",
          "-target=\"module.common.aws_eip.myapp\"",
          "-var-file=covalence-inputs.tfvars"
        )))
        subject.invoke
      end
    end

    describe "example:myapp:az1:plan_destroy" do
      include_context "rake"

      it "generates a state configuration" do
        buffer = StringIO.new()
        filename = 'covalence-state.tf'
        content = <<-CONF
terraform {
  backend "atlas" {
    name = "example/myapp"
  }
}
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "sources modules" do
        expect(TerraformCli).to receive(:terraform_get)
        subject.invoke
      end

      it "initializes the workspace" do
        expect(TerraformCli).to receive(:terraform_init)
        subject.invoke
      end

      it "generates an inputs varfile" do
        buffer = StringIO.new()
        filename = 'covalence-inputs.tfvars'
        content = <<-CONF
label = "test"
list_test_simple = [
  "foo",
  "bar",
]
map_test_simple = {
  "foo" = "bar"
  "bar" = "foo"
}
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "executes a plan" do
        expect(TerraformCli).to receive(:terraform_plan).with(hash_including(args: array_including(
          "-destroy",
          "-input=false",
          "-no-color",
          "-target=\"module.az1\"",
          "-target=\"module.common.aws_eip.myapp\"",
          "-var-file=covalence-inputs.tfvars"
        )))
        subject.invoke
      end
    end

    describe "example:myapp:az1:apply" do
      include_context "rake"

      it "generates a state configuration" do
        buffer = StringIO.new()
        filename = 'covalence-state.tf'
        content = <<-CONF
terraform {
  backend "atlas" {
    name = "example/myapp"
  }
}
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "sources modules" do
        expect(TerraformCli).to receive(:terraform_get)
        subject.invoke
      end

      it "initializes the workspace" do
        expect(TerraformCli).to receive(:terraform_init)
        subject.invoke
      end

      it "generates an inputs varfile" do
        buffer = StringIO.new()
        filename = 'covalence-inputs.tfvars'
        content = <<-CONF
label = "test"
list_test_simple = [
  "foo",
  "bar",
]
map_test_simple = {
  "foo" = "bar"
  "bar" = "foo"
}
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "executes an apply" do
        expect(TerraformCli).to receive(:terraform_apply).with(hash_including(args: array_including(
          "-input=false",
          "-auto-approve=true",
          "-no-color",
          "-target=\"module.az1\"",
          "-target=\"module.common.aws_eip.myapp\"",
          "-var-file=covalence-inputs.tfvars"
        )))
        subject.invoke
      end
    end

    describe "example:myapp:az1:destroy" do
      include_context "rake"

      it "generates a state configuration" do
        buffer = StringIO.new()
        filename = 'covalence-state.tf'
        content = <<-CONF
terraform {
  backend "atlas" {
    name = "example/myapp"
  }
}
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "sources modules" do
        expect(TerraformCli).to receive(:terraform_get)
        subject.invoke
      end

      it "initializes the workspace" do
        expect(TerraformCli).to receive(:terraform_init)
        subject.invoke
      end

      it "generates an inputs varfile" do
        buffer = StringIO.new()
        filename = 'covalence-inputs.tfvars'
        content = <<-CONF
label = "test"
list_test_simple = [
  "foo",
  "bar",
]
map_test_simple = {
  "foo" = "bar"
  "bar" = "foo"
}
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "executes a destroy" do
        expect(TerraformCli).to receive(:terraform_destroy).with(hash_including(args: [
          "-input=false",
          "-auto-approve=true",
          "-no-color",
          "-target=\"module.az1\"",
          "-target=\"module.common.aws_eip.myapp\"",
          "-var-file=covalence-inputs.tfvars"
        ]))
        subject.invoke
      end
    end

    describe "example:myapp:sync" do
      include_context "rake"

      it "generates the source & sync target state configuration" do
        buffer = StringIO.new()
        filename = 'covalence-state.tf'
        content = <<-CONF
terraform {
  backend "atlas" {
    name = "example/myapp"
  }
}
terraform {
  backend "s3" {
    key = "some_name/terraform.tfstate"
    bucket = "some_bucket"
    region = "some_region"
  }
}
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "should reinitiailze the backend and copy the state" do
        expect(TerraformCli).to receive(:terraform_init).at_most(:twice)
        subject.invoke
      end
    end

    describe "example:module_test:plan" do
      include_context "rake"

      it "generates a state configuration" do
        buffer = StringIO.new()
        filename = 'covalence-state.tf'
        content = <<-CONF
terraform {
  backend "atlas" {
    name = "example/myapp"
  }
}
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "sources modules" do
        expect(TerraformCli).to receive(:terraform_get)
        subject.invoke
      end

      it "initializes the workspace" do
        expect(TerraformCli).to receive(:terraform_init)
        subject.invoke
      end

      it "generates an inputs varfile" do
        buffer = StringIO.new()
        filename = 'covalence-inputs.tfvars'
        content = <<-CONF
list_test_lookup = [
  "foo",
  "bar",
]
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "executes a plan" do
        expect(TerraformCli).to receive(:terraform_plan).with(hash_including(args: [
          "-input=false",
          "-var-file=covalence-inputs.tfvars"
        ]))
        subject.invoke
      end
    end

    describe "example:module_test:plan_destroy" do
      include_context "rake"

      it "generates a state configuration" do
        buffer = StringIO.new()
        filename = 'covalence-state.tf'
        content = <<-CONF
terraform {
  backend "atlas" {
    name = "example/myapp"
  }
}
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "sources modules" do
        expect(TerraformCli).to receive(:terraform_get)
        subject.invoke
      end

      it "initializes the workspace" do
        expect(TerraformCli).to receive(:terraform_init)
        subject.invoke
      end

      it "generates an inputs varfile" do
        buffer = StringIO.new()
        filename = 'covalence-inputs.tfvars'
        content = <<-CONF
list_test_lookup = [
  "foo",
  "bar",
]
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "executes a plan" do
        expect(TerraformCli).to receive(:terraform_plan).with(hash_including(args: [
          "-destroy",
          "-input=false",
          "-var-file=covalence-inputs.tfvars"
        ]))
        subject.invoke
      end
    end

    describe "example:module_test:apply" do
      include_context "rake"

      it "generates a state configuration" do
        buffer = StringIO.new()
        filename = 'covalence-state.tf'
        content = <<-CONF
terraform {
  backend "atlas" {
    name = "example/myapp"
  }
}
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "sources modules" do
        expect(TerraformCli).to receive(:terraform_get)
        subject.invoke
      end

      it "initializes the workspace" do
        expect(TerraformCli).to receive(:terraform_init)
        subject.invoke
      end

      it "generates an inputs varfile" do
        buffer = StringIO.new()
        filename = 'covalence-inputs.tfvars'
        content = <<-CONF
list_test_lookup = [
  "foo",
  "bar",
]
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "executes an apply" do
        expect(TerraformCli).to receive(:terraform_apply).with(hash_including(args: [
          "-input=false",
          "-auto-approve=true",
          "-var-file=covalence-inputs.tfvars"
        ]))
        subject.invoke
      end
    end

    describe "example:module_test:destroy" do
      include_context "rake"

      it "generates a state configuration" do
        buffer = StringIO.new()
        filename = 'covalence-state.tf'
        content = <<-CONF
terraform {
  backend "atlas" {
    name = "example/myapp"
  }
}
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "sources modules" do
        expect(TerraformCli).to receive(:terraform_get)
        subject.invoke
      end

      it "initializes the workspace" do
        expect(TerraformCli).to receive(:terraform_init)
        subject.invoke
      end

      it "generates an inputs varfile" do
        buffer = StringIO.new()
        filename = 'covalence-inputs.tfvars'
        content = <<-CONF
list_test_lookup = [
  "foo",
  "bar",
]
CONF

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "executes a destroy" do
        expect(TerraformCli).to receive(:terraform_destroy).with(hash_including(args: [
          "-input=false",
          "-auto-approve=true",
          "-var-file=covalence-inputs.tfvars"
        ]))
        subject.invoke
      end
    end

    describe "example:plan_destroy" do
      include_context "rake"

      it "executes rake tasks in the correct order" do
        expect(Rake::Task).to receive(:[]).with("example:artifact_test:plan_destroy").and_call_original.ordered
        expect(Rake::Task).to receive(:[]).with("example:module_test:plan_destroy").and_call_original.ordered
        expect(Rake::Task).to receive(:[]).with("example:myapp:az0:plan_destroy").and_call_original.ordered
        expect(Rake::Task).to receive(:[]).with("example:myapp:az1:plan_destroy").and_call_original.ordered
        expect(Rake::Task).to receive(:[]).with("example:myapp:plan_destroy").and_call_original.ordered
        subject.invoke
      end

    end

    describe "example:destroy" do
      include_context "rake"

      it "executes rake tasks in the correct order" do
        expect(Rake::Task).to receive(:[]).with("example:artifact_test:destroy").and_call_original.ordered
        expect(Rake::Task).to receive(:[]).with("example:module_test:destroy").and_call_original.ordered
        expect(Rake::Task).to receive(:[]).with("example:myapp:az0:destroy").and_call_original.ordered
        expect(Rake::Task).to receive(:[]).with("example:myapp:az1:destroy").and_call_original.ordered
        expect(Rake::Task).to receive(:[]).with("example:myapp:destroy").and_call_original.ordered
        subject.invoke
      end
    end

=end

    describe "example:packer_test:packer-inspect" do
      include_context "rake"

      it "converts a YML build template to JSON" do
        buffer = StringIO.new()
        filename = 'covalence-packer-template.json'
        content = "{\"variables\":{\"aws_access_key\":\"\",\"aws_secret_key\":\"\"},\"builders\":[{\"type\":\"amazon-ebs\",\"access_key\":\"{{user `aws_access_key`}}\",\"secret_key\":\"{{user `aws_secret_key`}}\",\"region\":\"us-east-1\",\"source_ami\":\"ami-fce3c696\",\"instance_type\":\"t2.micro\",\"ssh_username\":\"ubuntu\",\"ami_name\":\"packer-example {{timestamp}}\"}]}"

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "inspects the build template" do
        expect(PackerCli).to receive(:packer_inspect)
        subject.invoke
      end
    end

    describe "example:packer_test:packer-validate" do
      include_context "rake"

      it "converts a YML build template to JSON" do
        buffer = StringIO.new()
        filename = 'covalence-packer-template.json'
        content = "{\"variables\":{\"aws_access_key\":\"\",\"aws_secret_key\":\"\"},\"builders\":[{\"type\":\"amazon-ebs\",\"access_key\":\"{{user `aws_access_key`}}\",\"secret_key\":\"{{user `aws_secret_key`}}\",\"region\":\"us-east-1\",\"source_ami\":\"ami-fce3c696\",\"instance_type\":\"t2.micro\",\"ssh_username\":\"ubuntu\",\"ami_name\":\"packer-example {{timestamp}}\"}]}"

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "generates an inputs varfile" do
        buffer = StringIO.new()
        filename = 'covalence-inputs.json'
        content = "{\"aws_access_key\":\"testing\",\"aws_secret_key\":\"testing\"}"

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "validates the build template" do
        expect(PackerCli).to receive(:packer_validate)
        subject.invoke
      end
    end

    describe "example:packer_test:packer-build" do
      include_context "rake"

      it "converts a YML build template to JSON" do
        buffer = StringIO.new()
        filename = 'covalence-packer-template.json'
        content = "{\"variables\":{\"aws_access_key\":\"\",\"aws_secret_key\":\"\"},\"builders\":[{\"type\":\"amazon-ebs\",\"access_key\":\"{{user `aws_access_key`}}\",\"secret_key\":\"{{user `aws_secret_key`}}\",\"region\":\"us-east-1\",\"source_ami\":\"ami-fce3c696\",\"instance_type\":\"t2.micro\",\"ssh_username\":\"ubuntu\",\"ami_name\":\"packer-example {{timestamp}}\"}]}"

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "generates an inputs varfile" do
        buffer = StringIO.new()
        filename = 'covalence-inputs.json'
        content = "{\"aws_access_key\":\"testing\",\"aws_secret_key\":\"testing\"}"

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "executes the build" do
        expect(PackerCli).to receive(:packer_build)
        subject.invoke
      end
    end
  end
end

