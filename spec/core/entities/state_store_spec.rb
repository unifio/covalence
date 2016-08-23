require 'spec_helper'
require_relative File.expand_path(PrometheusUnifio::GEM_ROOT, 'core/entities/state_store')

module PrometheusUnifio
  RSpec.describe StateStore do
    let(:state_store) do
      Fabricate(:state_store,
                params: { name: "example/state_store" },
                backend: "s3")
    end

    describe "validators" do
      it "requires a name in params" do
        expect{ Fabricate(:state_store, params: { foo: 'baz'}) }.to raise_error(
          ActiveModel::StrictValidationFailed, /missing 'name' param/)
      end

      it "requires the backend module to support state storage" do
        expect{ Fabricate(:state_store, backend: '') }.to raise_error(
          ActiveModel::StrictValidationFailed, /module does not support state storage/)
      end
    end

    describe '#name' do
      let(:name) { 'some name' }

      it "returns the name in params" do
        state_store = Fabricate(:state_store, params: { name: name })
        expect(state_store.name).to eq(name)
      end
    end

    describe '#get_config' do
      it "does call through to the backend to get the state store" do
        expect(S3).to receive(:get_state_store).with({"name" => "example/state_store"})
        state_store.get_config
      end
    end

    describe '#params' do
      it "should stringify hash keys" do
        symbol_keys = Fabricate(:state_store, params: { name: 'example/symbol'})
        expect(symbol_keys.params.fetch('name')).to eq('example/symbol')
        expect(symbol_keys.params.has_key?(:name)).to be false
      end
    end

    describe '#backend' do
      it "does set the backend class given a backend name string" do
        state_store = Fabricate(:state_store, backend: 'atlas')
        expect(state_store.backend).to eq(Atlas)
      end
    end
  end
end
