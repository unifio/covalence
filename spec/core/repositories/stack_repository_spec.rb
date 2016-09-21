require 'spec_helper'
require_relative File.join(Covalence::GEM_ROOT, 'core/data_stores/hiera')
require_relative File.join(Covalence::GEM_ROOT, 'core/repositories/stack_repository')

module Covalence
  RSpec.describe StackRepository do
    describe ".find" do
      context "with a valid stack" do
        let(:data_store) { HieraDB::Client.new("spec/fixtures/covalence_spec.yaml") }

        context "with a valid environment" do
          it "finds the stack with an valid environment" do
            stack = described_class.find(data_store, 'example', 'artifact_test')

            expect(stack.args).to_not be_empty
            expect(stack.inputs.has_key?('invalid_key')).to be false
            expect(stack.inputs['label'].value).to eq('test')
          end
        end

        context "with an invalid environment" do
          it "raises an error with an invalid environment" do
            expect {
              described_class.find(data_store, 'examplez', 'artifact_test')
            }.to raise_exception(RuntimeError, /missing 'state' hash/)
          end
        end
      end

      context "with an invalid stack" do
        let(:data_store) { HieraDB::Client.new("spec/fixtures/covalence_bad_state.yaml") }

        it "raises an error" do
          expect {
            described_class.find(data_store, 'example', 'bad_state')
          }.to raise_exception(RuntimeError, /missing 'state' hash/)
        end
      end
    end

    describe ".packer-find" do
      pending
    end
  end
end
