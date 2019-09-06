require 'spec_helper'
require_relative File.expand_path(Covalence::GEM_ROOT, 'core/entities/stack')

module Covalence
  RSpec.describe Stack do
    let(:stack) do
      Fabricate(:terraform_stack,
                inputs: {
                  'local_input' => Fabricate(:local_input),
                })
    end

    describe "validators" do
      it "does not allow names with spaces" do
        expect { Fabricate(:terraform_stack, name: "bad context") }.to raise_error(
          ActiveModel::StrictValidationFailed, /contain spaces/)
      end
    end

    describe "#full_name" do
      it "should return the full name" do
        expect(stack.full_name).to eq("example_environment-example_stack")
      end
    end

    it "#materialize_cmd_inputs" do
      tmpdir = Dir.mktmpdir
      buffer = StringIO.new()
      filename = "#{tmpdir}/covalence-inputs.tfvars"
      content = "local_input = \"foo\"\n"

      allow(File).to receive(:open).and_call_original
      allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
      allow_any_instance_of(Input).to receive(:to_command_option).and_return("local_input = \"foo\"")

      Dir.chdir(tmpdir) do
        stack.materialize_cmd_inputs(tmpdir)
      end

      expect(buffer.string).to eq(content)
    end

    it "#materialize_state_inputs" do
      tmpdir = Dir.mktmpdir
      buffer = StringIO.new()
      filename = "#{tmpdir}/covalence-state.tf"
      content = <<-CONF
terraform {
  backend "s3" {
    name = "exmpl/stack"
  }
}
CONF

      allow(File).to receive(:open).and_call_original
      allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
      allow_any_instance_of(StateStore).to receive(:get_config).and_return(content)

      Dir.chdir(tmpdir) do
        stack.materialize_state_inputs(path: tmpdir)
      end

      expect(buffer.string).to eq(content)
    end

    it "should accept empty args" do
      expect(Fabricate(:terraform_stack, args: '').args).to eql('')
    end

    it "should accept empty vars" do
      expect(Fabricate(:terraform_stack, inputs: {}).inputs).to eql({})
    end

    it "should accept empty targets" do
      expect(Fabricate(:terraform_stack, contexts: []).contexts).to eql([])
    end

    it "should accept an empty workspace" do
      expect(Fabricate(:terraform_stack, workspace: '').workspace).to eql('')
    end

    it "should yield state stores" do
      expect(stack.state_stores).to be_instance_of Array
      expect(stack.state_stores.all? {|store| store.instance_of?(StateStore)}).to be true
    end

    it "should yield args" do
      expect(stack.args).to eq('-no-color')
    end

    it "should yield inputs" do
      expect(stack.inputs).to be_instance_of Hash
      expect(stack.inputs.values.all? {|store| store.instance_of?(Input)}).to be true
    end

    it "should yield contexts" do
      expect(stack.contexts).to be_instance_of Array
      expect(stack.contexts.all? {|store| store.instance_of?(Context)}).to be true
    end

    it "should yield a workspace" do
      expect(stack.workspace).to be_instance_of String
      expect(stack.workspace).to eq('blue')
    end
  end
end
