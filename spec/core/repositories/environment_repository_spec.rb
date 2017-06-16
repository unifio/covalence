require 'spec_helper'
require_relative File.join(Covalence::GEM_ROOT, 'core/repositories/environment_repository')

module Covalence
  RSpec.describe EnvironmentRepository do
    describe ".all" do
      context "with valid Terraform stacks" do
        it "succeeds" do
          data_store = Object.new
          allow(data_store).to receive(:hash_lookup).with('environments').and_return({'environment_name' => %w(terraform_name)})
          allow(StackRepository).to receive(:find).and_return(
            Fabricate(:terraform_stack,
                      environment_name: 'environment_name',
                      name: 'terraform_name'))

          result = described_class.all(data_store)
          expect(result.size).to eq(1)
          expect(result.first.stacks.size).to eq(1)
          expect(result.first.stacks.first.environment_name).to eq('environment_name')
          expect(result.first.stacks.first.name).to eq('terraform_name')
          expect(result.first.stacks.any?(&:nil?)).to be false
        end
      end

      context "with valid Packer stacks" do
        it "succeeds" do
          data_store = Object.new
          allow(data_store).to receive(:hash_lookup).with('environments').and_return({'environment_name' => %w(packer_name)})
          allow(StackRepository).to receive(:find).and_return(
            Fabricate(:packer_stack,
                      environment_name: 'environment_name',
                      name: 'packer_name'), nil)

          result = described_class.all(data_store)
          expect(result.size).to eq(1)
          expect(result.first.stacks.size).to eq(1)
          expect(result.first.stacks.first.environment_name).to eq('environment_name')
          expect(result.first.stacks.first.name).to eq('packer_name')
          expect(result.first.stacks.any?(&:nil?)).to be false
        end
      end

      context "with an invalid stack" do
        let(:data_store) { HieraDB::Client.new("spec/fixtures/covalence_bad_state.yaml") }

        it "raise an error" do
          expect { described_class.all(data_store) }.to raise_error(RuntimeError, /Invalid stack\(s\) \["bad_state"\]/)
        end
      end
    end
  end
end
