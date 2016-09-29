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
          it "prints info about the invalid environment-stack combo" do
            expect(Covalence::LOGGER).to receive(:info).and_return(true)
            described_class.find(data_store, 'examplez', 'artifact_test')
          end

          it "returns nil" do
            expect(described_class.find(data_store, 'examplez', 'artifact_test')).to be_nil
          end
        end
      end

      context "with an invalid terraform stack" do
        let(:data_store) { HieraDB::Client.new("spec/fixtures/covalence_bad_state.yaml") }

        it "prints info about the invalid environment-stack combo" do
          expect(Covalence::LOGGER).to receive(:info).and_return(true)
          described_class.find(data_store, 'example', 'bad_state')
        end

        it "returns nil" do
          expect( described_class.find(data_store, 'example', 'bad_state')).to be_nil
        end
      end
    end

    describe ".packer-find" do
      pending
    end
  end
end
