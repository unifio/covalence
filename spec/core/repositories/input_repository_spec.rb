require 'yaml'
require 'tempfile'
require 'spec_helper'
require_relative File.join(Covalence::GEM_ROOT, 'core/repositories/input_repository')

module Covalence
  RSpec.describe InputRepository do
    let(:datastore) { Object.new }

    shared_examples "an InputRepository query" do
      context "with a vars file" do
        let(:file_data) { { "key" => "local value" } }

        before(:each) do
          allow(described_class).to receive(:query_tool_by_namespace).and_return({})
        end

        after(:each) do
          if @tmp_file
            @tmp_file.close
            @tmp_file.unlink
          end
        end

        it "sources a json vars file" do
          @tmp_file = Tempfile.new(['file', '.json'], tool_modules_path)
          @tmp_file.write(file_data.to_json)
          @tmp_file.rewind

          allow(datastore).to receive(:lookup).with(/#{vars_file_search_key}/, anything).and_return(@tmp_file.path.gsub(tool_modules_path, ''))

          expect(query_result).to have_key("key")
          expect(query_result["key"].raw_value).to eq('local value')
        end

        it "sources a yaml vars file" do
          @tmp_file = Tempfile.new(['file', '.yaml'], tool_modules_path)
          @tmp_file.write(file_data.to_yaml)
          @tmp_file.rewind

          allow(datastore).to receive(:lookup).with(/#{vars_file_search_key}/, anything).and_return(@tmp_file.path.gsub(tool_modules_path, ''))

          expect(query_result).to have_key("key")
          expect(query_result["key"].raw_value).to eq('local value')
        end

        it "raises an error on non-json and non-yaml files" do
          @tmp_file = Tempfile.new(['file', '.txt'], tool_modules_path)
          @tmp_file.write('some text')
          @tmp_file.rewind

          allow(datastore).to receive(:lookup).with(/#{vars_file_search_key}/, anything).and_return(@tmp_file.path.gsub(tool_modules_path, ''))

          expect { query_result }.to raise_error(ArgumentError, /cannot parse/)
        end

        it "raises an error on malformed json files" do
          @tmp_file = Tempfile.new(['file', '.json'], tool_modules_path)
          @tmp_file.write('some text')
          @tmp_file.rewind

          allow(datastore).to receive(:lookup).with(/#{vars_file_search_key}/, anything).and_return(@tmp_file.path.gsub(tool_modules_path, ''))

          expect { query_result }.to raise_error(JSON::ParserError, /unexpected token/)
        end

        it "raises an error on malformed yaml files" do
          @tmp_file = Tempfile.new(['file', '.yaml'], tool_modules_path)
          @tmp_file.write('some : : text')
          @tmp_file.rewind

          allow(datastore).to receive(:lookup).with(/#{vars_file_search_key}/, anything).and_return(@tmp_file.path.gsub(tool_modules_path, ''))

          expect { query_result }.to raise_error(Psych::SyntaxError)
        end

        it "allows normal inputs to override the vars file" do
          @tmp_file = Tempfile.new(['file', '.json'], tool_modules_path)
          @tmp_file.write(file_data.to_json)
          @tmp_file.rewind

          allow(datastore).to receive(:lookup).with(/#{vars_file_search_key}/, anything).and_return(@tmp_file.path.gsub(tool_modules_path, ''))
          allow(described_class).to receive(:query_tool_by_namespace).and_call_original
          allow(datastore).to receive(:hash_lookup).with(/#{vars_search_key}/, anything).and_return("key" => "non-file value")
          expect(query_result).to have_key("key")
          expect(query_result["key"].raw_value).to eq('non-file value')
        end
      end

      it "returns a hash of names and inputs" do
      end
    end

    describe ".query_terraform_by_namespace" do
      it_behaves_like "an InputRepository query" do
        let(:query_result) { described_class.query_terraform_by_namespace(datastore, 'foo') }
        let(:vars_search_key) { "::vars" }
        let(:vars_file_search_key) { "::vars-file" }
        let(:tool_modules_path) { TERRAFORM }
      end
    end

    describe ".query_packer_by_namespace" do
      it_behaves_like "an InputRepository query" do
        let(:query_result) { described_class.query_packer_by_namespace(datastore, 'foo') }
        let(:vars_search_key) { "::packer-vars" }
        let(:vars_file_search_key) { "::packer-vars-file" }
        let(:tool_modules_path) { PACKER }
      end
    end
  end
end
