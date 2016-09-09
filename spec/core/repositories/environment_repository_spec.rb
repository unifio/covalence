require 'spec_helper'
require_relative File.join(Covalence::GEM_ROOT, 'core/repositories/environment_repository')

module Covalence
  RSpec.describe EnvironmentRepository do
    it ".all" do
      data_store = Object.new
      allow(data_store).to receive(:hash_lookup).with('environments').and_return({'environment' => %w(stack1 stack2)})
      allow(StackRepository).to receive(:find).and_return(
        Fabricate(:terraform_stack,
                  environment_name: 'environment_name',
                  name: 'terraform_name'))
      allow(StackRepository).to receive(:packer_find).and_return(
        Fabricate(:packer_stack,
                  environment_name: 'environment_name',
                  name: 'packer_name'), nil)

      result = described_class.all(data_store)
      expect(result.size).to eq(1)
      expect(result.first.stacks.size).to eq(2)
      expect(result.first.stacks.first.environment_name).to eq('environment_name')
      expect(result.first.stacks.first.name).to eq('terraform_name')
      expect(result.first.stacks.any?(&:nil?)).to be false
      expect(result.first.packer_stacks.size).to eq(1)
      expect(result.first.packer_stacks.first.environment_name).to eq('environment_name')
      expect(result.first.packer_stacks.first.name).to eq('packer_name')
      expect(result.first.packer_stacks.any?(&:nil?)).to be false
    end
  end
end
