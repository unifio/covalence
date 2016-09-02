require 'spec_helper'
require 'active_support/core_ext/kernel/reporting'

require_relative File.join(PrometheusUnifio::GEM_ROOT, 'core/cli_wrappers/terraform_cli')
require_relative File.join(PrometheusUnifio::GEM_ROOT, 'core/cli_wrappers/popen_wrapper')
require_relative File.join(PrometheusUnifio::GEM_ROOT, 'environment_tasks')
require_relative '../shared_contexts/rake.rb'

module PrometheusUnifio
  describe EnvironmentTasks do
    let(:task_files) { "environment_tasks.rb" }

    before(:each) do
      Kernel.silence_warnings {
        PrometheusUnifio::TERRAFORM_VERSION = "0.7.0"
      }
      allow(PopenWrapper).to receive(:run).and_return(true)
      # suppress FileUtils verbose
      allow($stderr).to receive(:write)
      allow(Atlas).to receive(:get_artifact).and_return('artifact')
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

    describe "example:myapp:verify" do
      include_context "rake"

      it "cleans the workspace" do
        expect(TerraformCli).to receive(:terraform_clean)
        subject.invoke
      end

      it "gets Terraform modules" do
        expect(TerraformCli).to receive(:terraform_get)
        subject.invoke
      end

      it "executes template validation" do
        expect(TerraformCli).to receive(:terraform_validate)
        subject.invoke
      end

      it "executes a plan" do
        expect(TerraformCli).to receive(:terraform_plan).with(anything, hash_including(args: [
          "-var 'label=\"test\"'",
          "-input=false",
          "-module-depth=-1",
          "-no-color"
        ]))
        subject.invoke
      end
    end

    describe "example:myapp:az0:plan" do
      include_context "rake"

      it "cleans the workspace" do
        expect(TerraformCli).to receive(:terraform_clean)
        subject.invoke
      end

      it "configures remote state" do
        expect(TerraformCli).to receive(:terraform_remote_config).at_most(:twice)
        subject.invoke
      end

      it "gets Terraform modules" do
        expect(TerraformCli).to receive(:terraform_get)
        subject.invoke
      end

      it "executes a plan" do
        expect(TerraformCli).to receive(:terraform_plan).with(anything, hash_including(args: [
          "-var 'label=\"test\"'",
          "-input=false",
          "-module-depth=-1",
          "-no-color",
          "-target=\"module.az0\""
        ]))
        subject.invoke
      end
    end

    describe "example:myapp:az0:plan_destroy" do
      include_context "rake"

      it "cleans the workspace" do
        expect(TerraformCli).to receive(:terraform_clean)
        subject.invoke
      end

      it "gets Terraform modules" do
        expect(TerraformCli).to receive(:terraform_get)
        subject.invoke
      end

      it "executes a plan" do
        expect(TerraformCli).to receive(:terraform_plan).with(anything, hash_including(args: [
          "-var 'label=\"test\"'",
          "-destroy",
          "-input=false",
          "-module-depth=-1",
          "-no-color",
          "-target=\"module.az0\""
        ]))
        subject.invoke
      end
    end

    describe "example:myapp:az0:apply" do
      include_context "rake"

      it "cleans the workspace" do
        expect(TerraformCli).to receive(:terraform_clean)
        subject.invoke
      end

      it "configures remote state" do
        expect(TerraformCli).to receive(:terraform_remote_config)
        subject.invoke
      end

      it "gets Terraform modules" do
        expect(TerraformCli).to receive(:terraform_get)
        subject.invoke
      end

      it "executes a plan" do
        expect(TerraformCli).to receive(:terraform_plan).with(anything, hash_including(args: array_including(
          "-var 'label=\"test\"'",
          "-input=false",
          "-module-depth=-1",
          "-no-color",
          "-target=\"module.az0\""
        )))
        subject.invoke
      end

      it "executes an apply" do
        expect(TerraformCli).to receive(:terraform_apply).with(anything, hash_including(args: [
          "-var 'label=\"test\"'",
          "-no-color",
          "-target=\"module.az0\""
        ]))
        subject.invoke
      end
    end

    describe "example:myapp:az0:destroy" do
      include_context "rake"

      it "cleans the workspace" do
        expect(TerraformCli).to receive(:terraform_clean)
        subject.invoke
      end

      it "configures remote state" do
        expect(TerraformCli).to receive(:terraform_remote_config)
        subject.invoke
      end

      it "gets Terraform modules" do
        expect(TerraformCli).to receive(:terraform_get)
        subject.invoke
      end

      it "executes a plan" do
        expect(TerraformCli).to receive(:terraform_plan).with(anything, hash_including(args: array_including(
          "-var 'label=\"test\"'",
          "-destroy",
          "-input=false",
          "-module-depth=-1",
          "-no-color",
          "-target=\"module.az0\""
        )))
        subject.invoke
      end

      it "executes a destroy" do
        expect(TerraformCli).to receive(:terraform_destroy).with(anything, hash_including(args: [
          "-var 'label=\"test\"'",
          "-no-color",
          "-target=\"module.az0\""
        ]))
        subject.invoke
      end
    end

    describe "example:myapp:az1:plan" do
      include_context "rake"

      it "executes a plan" do
        expect(TerraformCli).to receive(:terraform_plan).with(anything, hash_including(args: [
          "-var 'label=\"test\"'",
          "-input=false",
          "-module-depth=-1",
          "-no-color",
          "-target=\"module.az1\"",
          "-target=\"module.common.aws_eip.myapp\""
        ]))
        subject.invoke
      end
    end

    describe "example:myapp:az1:plan_destroy" do
      include_context "rake"

      it "executes a plan" do
        expect(TerraformCli).to receive(:terraform_plan).with(anything, hash_including(args: [
          "-var 'label=\"test\"'",
          "-destroy",
          "-input=false",
          "-module-depth=-1",
          "-no-color",
          "-target=\"module.az1\"",
          "-target=\"module.common.aws_eip.myapp\""
        ]))
        subject.invoke
      end
    end

    describe "example:myapp:az1:apply" do
      include_context "rake"

      it "executes a plan" do
        expect(TerraformCli).to receive(:terraform_plan).with(anything, hash_including(args: array_including(
          "-var 'label=\"test\"'",
          "-input=false",
          "-module-depth=-1",
          "-no-color",
          "-target=\"module.az1\"",
          "-target=\"module.common.aws_eip.myapp\""
        )))
        subject.invoke
      end

      it "executes an apply" do
        expect(TerraformCli).to receive(:terraform_apply).with(anything, hash_including(args: [
          "-var 'label=\"test\"'",
          "-no-color",
          "-target=\"module.az1\"",
          "-target=\"module.common.aws_eip.myapp\""
        ]))
        subject.invoke
      end
    end

    describe "example:myapp:az1:destroy" do
      include_context "rake"

      it "executes a plan" do
        expect(TerraformCli).to receive(:terraform_plan).with(anything, hash_including(args: array_including(
          "-var 'label=\"test\"'",
          "-destroy",
          "-input=false",
          "-module-depth=-1",
          "-no-color",
          "-target=\"module.az1\"",
          "-target=\"module.common.aws_eip.myapp\""
        )))
        subject.invoke
      end

      it "executes a destroy" do
        expect(TerraformCli).to receive(:terraform_destroy).with(anything, hash_including(args: [
          "-var 'label=\"test\"'",
          "-no-color",
          "-target=\"module.az1\"",
          "-target=\"module.common.aws_eip.myapp\""
        ]))
        subject.invoke
      end
    end

    describe "example:myapp:sync" do
      include_context "rake"

      it "cleans the workspace" do
        expect(TerraformCli).to receive(:terraform_clean)
        subject.invoke
      end

      it "should sync state from the primary remote state" do
        expect(TerraformCli).to receive(:terraform_remote_config).with(args: /-backend=Atlas/)
        expect(TerraformCli).to receive(:terraform_remote_config).with(args: '-disable')
        expect(TerraformCli).to receive(:terraform_remote_config).with(args: /-backend=s3/)
        expect(TerraformCli).to receive(:terraform_remote_push)
        subject.invoke
      end
    end

    describe "example:module_test:plan" do
      include_context "rake"

      it "executes a plan" do
        expect(TerraformCli).to receive(:terraform_plan).with(anything, hash_including(args: [
          "-input=false",
          "-module-depth=-1"
        ]))
        subject.invoke
      end
    end

    describe "example:module_test:plan_destroy" do
      include_context "rake"

      it "executes a plan" do
        expect(TerraformCli).to receive(:terraform_plan).with(anything, hash_including(args: [
          "-destroy",
          "-input=false",
          "-module-depth=-1"
        ]))
        subject.invoke
      end
    end

    describe "example:module_test:apply" do
      include_context "rake"

      it "executes a plan" do
        expect(TerraformCli).to receive(:terraform_plan).with(anything, hash_including(args: [
          "-input=false",
          "-module-depth=-1"
        ]))
        subject.invoke
      end

      it "executes an apply" do
        expect(TerraformCli).to receive(:terraform_apply).with(anything, hash_including(args: []))
        subject.invoke
      end
    end

    describe "example:module_test:destroy" do
      include_context "rake"

      it "executes a plan" do
        expect(TerraformCli).to receive(:terraform_plan).with(anything, hash_including(args: [
          "-destroy",
          "-input=false",
          "-module-depth=-1"
        ]))
        subject.invoke
      end

      it "executes a destroy" do
        expect(TerraformCli).to receive(:terraform_destroy).with(anything, hash_including(args: []))
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
  end
end
