require 'spec_helper'
require_relative File.join(Covalence::GEM_ROOT, 'core/services/packer_stack_tasks')

module Covalence
  RSpec.describe PackerStackTasks do
    let(:environment_name) { "example_environment" }
    let(:packer_template) { 'packer_template' }
    let(:args) { '-args' }
    let(:name) { 'name' }
    let(:stack) do
      Fabricate(:packer_stack,
                name: name,
                environment_name: environment_name,
                packer_template: packer_template,
                args: args,
                inputs: {
                  'local_input' => Fabricate(:local_input, type: 'packer'),
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
      it "calls packer build with specific args" do
        expect(PackerCli).to receive(:public_send).with(
          :packer_build, anything, { args: array_including(
            "-var 'local_input=foo'",
            args
          )})
        described_class.new(stack).context_build
      end

      # TODO: check tempfile is generated in packer module directory
    end

    describe "#context_inspect" do
      it "calls packer inspect with specific args" do
        expect(PackerCli).to receive(:public_send).with(:packer_inspect, anything, { args: [] })
        described_class.new(stack).context_inspect
      end
    end

    describe "#context_validate" do
      it "calls packer validate with specific args" do
        expect(PackerCli).to receive(:public_send).with(
          :packer_validate, anything, { args: array_including(
            "-var 'local_input=foo'",
            args
          )})
        described_class.new(stack).context_validate
      end
    end
  end
end

