require 'spec_helper'
require_relative File.join(Covalence::GEM_ROOT, 'core/data_stores/hiera')
require_relative File.join(Covalence::GEM_ROOT, 'core/repositories/stack_repository')

module Covalence
  RSpec.describe StackRepository do
    describe ".find" do
      context "with a valid stack" do
        pending
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
