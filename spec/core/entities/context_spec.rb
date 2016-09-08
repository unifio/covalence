require 'spec_helper'
require_relative File.expand_path(PrometheusUnifio::GEM_ROOT, 'core/entities/context')

module PrometheusUnifio
  RSpec.describe Context do
    describe "validators" do
      it "does not allow names with spaces" do
        expect { Fabricate(:context, name: "bad context") }.to raise_error(
          ActiveModel::StrictValidationFailed, /contain spaces/)
      end
    end

    describe "#namespace" do
      it "returns a rake compatible namespace" do
        expect(Fabricate(:context, name: 'example_context').namespace).to eq('example_context:')
      end

      it "does not create a new namespace for an empty name" do
        expect(Fabricate(:context, name: '').namespace).to eq('')
        expect(Fabricate(:context, name: nil).namespace).to eq('')
      end

      it "fails name validation" do
        expect{ Fabricate(:context, name: 'name with spaces') }.to raise_error(ActiveModel::StrictValidationFailed, /cannot contain spaces or commas/)
        expect{ Fabricate(:context, name: 'name,with,commas') }.to raise_error(ActiveModel::StrictValidationFailed, /cannot contain spaces or commas/)
      end
    end

    it "#to_command_options" do
      expect(Fabricate(:context, values: %w()).to_command_options).to eq([])
      expect(Fabricate(:context, values: %w(foo baz)).to_command_options).to eq(["-target=\"foo\"","-target=\"baz\""])
    end

    it "#to_packer_command_options" do
      expect(Fabricate(:context, values: %w()).to_packer_command_options).to eq("")
      expect(Fabricate(:context, values: %w(foo baz)).to_packer_command_options).to eq("-only=foo,baz")
    end
  end
end
