require 'spec_helper'
require_relative File.join(Covalence::GEM_ROOT, 'core/repositories/context_repository')

module Covalence
  RSpec.describe ContextRepository do
    let(:datastore) { Object.new }

    shared_examples "a ContextRepository query" do
      context "with no context" do
        it 'will always create one global(blank) context' do
          allow(datastore).to receive(:hash_lookup).with(/#{search_key}/, anything).and_return({})

          expect(query_result.size).to eq(1)
          expect(query_result.first.name).to eq('')
          expect(query_result.first.values).to be_empty
        end
      end

      context "with context" do
        it "creates context and global context" do
          allow(datastore).to receive(:hash_lookup).with(/#{search_key}/, anything).and_return(name: ['values'])

          expect(query_result.size).to eq(2)
          expect(query_result.first.name).to eq('name')
          expect(query_result.first.values).to eq(['values'])
          expect(query_result[-1].name).to eq('')
          expect(query_result[-1].values).to be_empty
        end
      end
    end

    describe ".query_terraform_by_namespace" do
      it_behaves_like "a ContextRepository query" do
        let(:query_result) { described_class.query_terraform_by_namespace(datastore, 'foo') }
        let(:search_key) { "::targets" }
      end
    end


    describe ".query_packer_by_namespace" do
      it_behaves_like "a ContextRepository query" do
        let(:query_result) { described_class.query_packer_by_namespace(datastore, 'foo') }
        let(:search_key) { "::packer-targets" }
      end
    end
  end
end
