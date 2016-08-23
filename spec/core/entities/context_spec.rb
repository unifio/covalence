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
      end
    end

    pending "#to_command_option"
  end
end
