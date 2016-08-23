require 'spec_helper'
require 'active_support/core_ext/hash'
require_relative File.expand_path(PrometheusUnifio::GEM_ROOT, 'core/entities/input')

module PrometheusUnifio
  RSpec.describe Input do
    let(:input) { Fabricate(:input, raw_value: raw_value) }

    describe "validators" do
      it "does not allow remote inputs without 'type'" do
        expect{ Fabricate(:input, raw_value: { foo: 'baz' }) }.to raise_error(
          ActiveModel::StrictValidationFailed, /'type' not specified/)
      end
    end

    context "with local input" do
      let(:raw_value) { "test" }

      it { expect(input.value).to eq(raw_value) }
    end

    context "with remote input" do
      let(:test_backend_class) { PrometheusUnifio::TestBackend = Class.new(Object) }
      let(:raw_value) { { type: "test_backend.#{subcategory}", more: 'data' }.stringify_keys }

      let(:subcategory) { 'subcategory' }
      let(:remote_value) { 'remote_value' }

      before do
        expect(test_backend_class).to receive(:lookup).with(subcategory, raw_value).and_return(remote_value)
      end

      it "returns the value for a non-local key by calling the backend lookup" do
        expect(input.value).to eq(remote_value)
        expect(input.raw_value).to_not eq(remote_value)
      end

      pending "#to_command_option"
    end

    describe "#to_command_option" do
      let(:raw_value) { "test" }
      before(:each) do
        ENV['TERRAFORM_VERSION'] = tf_version
        # force constants to re-init
        Kernel.silence_warnings {
          load File.join(PrometheusUnifio::GEM_ROOT, '../prometheus-unifio.rb')
        }
      end

      context "with Terraform Version < 0.7.0" do
        let(:tf_version) { "0.6.5" }

        it { expect(input.to_command_option).to eq("-var input=\"test\"") }
      end

      context "with Terraform Version >= 0.7.0" do
        let(:tf_version) { "0.7.0" }

        it { expect(input.to_command_option).to eq("-var 'input=\"test\"'") }
      end
    end
  end
end
