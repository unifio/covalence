require 'spec_helper'
require_relative File.join(Covalence::GEM_ROOT, 'core/services/packer_stack_tasks')

module Covalence
  RSpec.describe PackerStackTasks do
    let(:environment_name) { "example_environment" }
    let(:args) { '-args' }
    let(:name) { 'name' }
    let(:module_path) { 'packer/example-build' }
    let(:packer_template) { 'packer_template.yml' }
    let(:stack) do
      Fabricate(:packer_stack,
                name: name,
                environment_name: environment_name,
                module_path: module_path,
                packer_template: packer_template,
                args: args,
                inputs: {
                  'local_input' => Fabricate(:local_input),
                })
    end

    before(:each) do
      allow(PackerCli).to receive(:public_send)
    end

    describe "#stack_name" do
      it "returns the stack name" do
        expect(described_class.new(stack).stack_name).to eq(name)
      end
    end

    describe "#environment_name" do
      it "returns the environment name" do
        expect(described_class.new(stack).environment_name).to eq(environment_name)
      end
    end

    describe "#context_build" do
      tmpdir = Dir.mktmpdir
      it "generates an inputs JSON file" do
        buffer = StringIO.new()
        filename = "#{tmpdir}/covalence-inputs.json"
        content = "{\"local_input\":\"foo\"}"
        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        Dir.chdir(tmpdir) do
          stack.materialize_cmd_inputs(tmpdir)
        end
        described_class.new(stack).context_build
        expect(buffer.string).to eq(content)
      end

      it "converts a YML build template to JSON" do
        buffer = StringIO.new()
        filename = "covalence-packer-template.json"
        content = "{\"variables\":{\"aws_access_key\":\"\",\"aws_secret_key\":\"\"},\"builders\":[{\"type\":\"amazon-ebs\",\"access_key\":\"{{user `aws_access_key`}}\",\"secret_key\":\"{{user `aws_secret_key`}}\",\"region\":\"us-east-1\",\"source_ami\":\"ami-fce3c696\",\"instance_type\":\"t2.micro\",\"ssh_username\":\"ubuntu\",\"ami_name\":\"packer-example {{timestamp}}\"}]}"

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        Dir.chdir(tmpdir) do
          stack.materialize_cmd_inputs(tmpdir)
        end
        described_class.new(stack).context_build
        expect(buffer.string).to eq(content)
      end

      it "calls packer build with specific args" do
        Dir.chdir(tmpdir) do
          stack.materialize_cmd_inputs(tmpdir)
        end
        expect(PackerCli).to receive(:public_send).with(
          :packer_build, anything, { args: array_including(
            args,
            "-var-file=covalence-inputs.json"
          )})
        described_class.new(stack).context_build
      end
    end

    describe "#context_inspect" do
      it "calls packer inspect with specific args" do
        expect(PackerCli).to receive(:public_send).with(:packer_inspect, anything, { args: [] })
        described_class.new(stack).context_inspect
      end
    end

    describe "#context_validate" do
      tmpdir = Dir.mktmpdir
      it "generates an inputs JSON file" do
        buffer = StringIO.new()
        filename = "#{tmpdir}/covalence-inputs.json"
        content = "{\"local_input\":\"foo\"}"
        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        Dir.chdir(tmpdir) do
          stack.materialize_cmd_inputs(tmpdir)
        end
        described_class.new(stack).context_build
        expect(buffer.string).to eq(content)
      end

      it "calls packer validate with specific args" do
        Dir.chdir(tmpdir) do
          stack.materialize_cmd_inputs(tmpdir)
        end
        expect(PackerCli).to receive(:public_send).with(
          :packer_validate, anything, { args: array_including(
            args,
            "-var-file=covalence-inputs.json"
          )})
        described_class.new(stack).context_validate
      end
    end
  end
end

