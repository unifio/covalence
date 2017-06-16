require 'spec_helper'
require_relative File.join(Covalence::GEM_ROOT, 'core/data_stores/hiera')
require_relative File.join(Covalence::GEM_ROOT, 'core/repositories/stack_repository')

module Covalence
  RSpec.describe StackRepository do
    describe ".find" do
      context "Terraform" do
        context "with a valid stack" do
          let(:data_store) { HieraDB::Client.new("spec/fixtures/covalence_spec.yaml") }

          context "with a valid environment" do
            it "finds the stack" do
              stack = described_class.find(data_store, 'example', 'artifact_test')

              expect(stack.type).to eq('terraform')
              expect(stack.name).to eq('artifact_test')
              expect(stack.environment_name).to eq('example')
              expect(stack.module_path).to eq('myapp2')

              expect(stack.dependencies).to be_empty
              expect(stack.packer_template).to be_nil
              expect(stack.state_stores).to be_empty
              expect(stack.contexts).to be_empty
              expect(stack.inputs).to be_empty
              expect(stack.args).to be_nil
            end
          end

          context "with an invalid environment" do
            it "prints info about the invalid environment-stack combo" do
              expect(Covalence::LOGGER).to receive(:debug).and_return(true)
              described_class.find(data_store, 'examplez', 'artifact_test')
            end

            it "returns nil" do
              expect(described_class.find(data_store, 'examplez', 'artifact_test')).to be_nil
            end
          end
        end

        context "with an invalid stack" do
          let(:data_store) { HieraDB::Client.new("spec/fixtures/covalence_bad_state.yaml") }

          it "prints info about the invalid environment-stack combo" do
            expect(Covalence::LOGGER).to receive(:debug).and_return(true)
            described_class.find(data_store, 'example', 'bad_state')
          end

          it "returns nil" do
            expect( described_class.find(data_store, 'example', 'bad_state')).to be_nil
          end
        end
      end

      context "Packer" do
        context "with a valid stack" do
          let(:data_store) { HieraDB::Client.new("spec/fixtures/covalence_spec.yaml") }

          context "with a valid environment" do
            it "finds the stack" do
              stack = described_class.find(data_store, 'example', 'packer_test')

              expect(stack.type).to eq('packer')
              expect(stack.name).to eq('packer_test')
              expect(stack.environment_name).to eq('example')
              expect(stack.module_path).to eq('packer/example-build')

              expect(stack.dependencies).to be_empty
              expect(stack.packer_template).to be_nil
              expect(stack.state_stores).to be_empty
              expect(stack.contexts).to be_empty
              expect(stack.inputs).to be_empty
              expect(stack.args).to be_nil
            end
          end

          context "with an invalid environment" do
            it "prints info about the invalid environment-stack combo" do
              expect(Covalence::LOGGER).to receive(:debug).and_return(true)
              described_class.find(data_store, 'examplez', 'packer_test')
            end

            it "returns nil" do
              expect(described_class.find(data_store, 'examplez', 'packer_test')).to be_nil
            end
          end
        end

        context "with an invalid stack" do
          let(:data_store) { HieraDB::Client.new("spec/fixtures/covalence_bad_state.yaml") }

          it "prints info about the invalid environment-stack combo" do
            expect(Covalence::LOGGER).to receive(:debug).and_return(true)
            described_class.find(data_store, 'example', 'bad_state')
          end

          it "returns nil" do
            expect( described_class.find(data_store, 'example', 'bad_state')).to be_nil
          end
        end
      end
    end

    describe ".populate" do
      context "Terraform" do
        context "with a valid stack" do
          let(:data_store) { HieraDB::Client.new("spec/fixtures/covalence_spec.yaml") }

          context "with a valid environment" do
            it "populates the stack" do
              stack = described_class.find(data_store, 'example', 'artifact_test')
              described_class.populate(data_store, stack)

              expect(stack.inputs.has_key?('invalid_key')).to be false
              expect(stack.inputs['label'].value).to eq('test')

              expect(stack.packer_template).to be_nil
              expect(stack.state_stores).to_not be_empty
              expect(stack.contexts).to_not be_empty
              expect(stack.inputs).to_not be_empty
              expect(stack.args).to_not be_empty
            end
          end
        end
      end

      context "Packer" do
        context "with a valid stack" do
          let(:data_store) { HieraDB::Client.new("spec/fixtures/covalence_spec.yaml") }

          context "with a valid environment" do
            it "populates the stack" do
              stack = described_class.find(data_store, 'example', 'packer_test')
              described_class.populate(data_store, stack)

              expect(stack.inputs.has_key?('invalid_key')).to be false
              expect(stack.inputs['aws_access_key'].value).to eq('testing')

              expect(stack.dependencies).to_not be_empty
              expect(stack.packer_template).to_not be_nil
              expect(stack.state_stores).to be_empty
              expect(stack.contexts).to_not be_empty
              expect(stack.inputs).to_not be_empty
              expect(stack.args).to_not be_nil
            end
          end
        end
      end
    end

  end
end
