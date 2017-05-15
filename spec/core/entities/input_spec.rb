require 'spec_helper'
require 'active_support/core_ext/hash'
require_relative File.expand_path(Covalence::GEM_ROOT, 'core/entities/input')

module Covalence
  RSpec.describe Input do
    let(:input) { Fabricate(:input, raw_value: raw_value) }

    context "with local input" do

      context "simple string" do
        let(:raw_value) { "test" }

        it { expect(input.value).to eq(raw_value) }
      end

      context "simple list" do
        let(:raw_value) { ["test"] }

        it { expect(input.value).to eq(raw_value) }
      end

      context "simple map" do
        let(:raw_value) { {"foo"=>"bar"} }

        it { expect(input.value).to eq(raw_value) }
      end

      context "complex string" do
        let(:raw_value) { {"type"=>"string","value"=>"test"} }

        it { expect(input.value).to eq("test") }
      end

      context "complex list" do
        let(:raw_value) { {"type"=>"string","value"=>["test"]} }

        it { expect(input.value).to eq(["test"]) }
      end

      context "complex map" do
        let(:raw_value) { {"type"=>"string","value"=>{"foo"=>"bar"}} }

        it { expect(input.value).to eq({"foo"=>"bar"}) }
      end
    end

    context "with remote input" do
      let(:test_backend_class) { Covalence::TestBackend = Class.new(Object) }
      let(:raw_value) { { type: "test_backend.#{subcategory}", more: 'data' }.stringify_keys }

      let(:subcategory) { 'subcategory' }
      let(:remote_value) { 'remote_value' }

      before do
        expect(test_backend_class).to receive(:lookup).with(subcategory, raw_value).and_return(remote_value)
      end

      context "Terraform state output" do
        let(:remote_value) do
          {
            "sensitive": false,
            "type": "string",
            "value": "foo"
          }
        end

        before(:each) do
          # force constants to re-init
          Kernel.silence_warnings {
            load File.join(Covalence::GEM_ROOT, '../covalence.rb')
          }
        end

        it 'returns the value' do
          expect(input.value).to eq("foo")
        end
      end
    end

    describe "#to_command_option" do
      let(:raw_value) { "test" }

      before(:each) do
        # force constants to re-init
        Kernel.silence_warnings {
          load File.join(Covalence::GEM_ROOT, '../covalence.rb')
        }
      end

      context "with nil value" do
        let(:raw_value) { nil }

        it { expect(input.to_command_option).to eq("input = \"\"") }
      end

      context "with list value" do
        let(:raw_value) { ["test"] }

        it { expect(input.to_command_option).to eq("input = [\n  \"test\",\n]") }
      end

      context "with map value" do
        let(:raw_value) { {"foo"=>"bar"} }

        it { expect(input.to_command_option).to eq("input = {\n  \"foo\" = \"bar\"\n}") }
      end

      context "with interpolated shell value" do
        let(:raw_value) { "$(pwd)" }

        it { expect(input.to_command_option).to eq("input = \"#{`pwd`.chomp}\"") }
      end

      context "all other values" do
        it { expect(input.to_command_option).to eq("input = \"test\"") }
      end
    end
  end
end
