require 'spec_helper'
require_relative File.expand_path(PrometheusUnifio::GEM_ROOT, 'core/entities/stack')

module PrometheusUnifio
  RSpec.describe Stack do
    let(:stack) { Fabricate(:terraform_stack) }

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
      allow_any_instance_of(Input).to receive(:to_command_option).and_return("-var 'local_input=\"value\"'")
      expect(stack.materialize_cmd_inputs).to eq(["-var 'local_input=\"value\"'"] * 2)
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
  end
end
