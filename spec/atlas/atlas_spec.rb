require_relative '../../ruby/lib/tools/atlas.rb'
require 'webmock/rspec'

RSpec.describe Atlas do

  context "Artifact" do
    before(:each) do
      @stub = stub_request(:any, /#{Atlas::URL}.*/).
        to_return(:body => File.new('./spec/atlas/artifact_response.json'), :status => 200)
      Atlas::reset_cache
    end

    it "is returned given a slug, version and metadata" do
      ami_id = Atlas::get_artifact('unifio/centos-base/amazon.ami', 1, 'region.us-east-1')
      expect(ami_id).to eql('ami-12345678')
    end

    it "is not returned if not found" do
      @stub = stub_request(:any, /#{Atlas::URL}.*/).
        to_return(:body => "", :status => 404)
      Atlas::reset_cache

      expect {
        Atlas::get_artifact('unifio/centos-base/amazon.ami', 1, 'region.us-east-1')
      }.to raise_error(RuntimeError)
    end

    it "is not returned if it does not contain the requested metadata" do
      @stub = stub_request(:any, /#{Atlas::URL}.*/).
        to_return(:body => File.new('./spec/atlas/artifact_response.json'), :status => 200)
      Atlas::reset_cache

      expect {
        Atlas::get_artifact('unifio/centos-base/amazon.ami', 20, 'region.us-west-1')
      }.to raise_error(RuntimeError)
    end

    it "caches multiple requests" do
      Atlas::get_artifact('unifio/centos-base/amazon.ami', 1, 'region.us-east-1')
      Atlas::get_artifact('unifio/centos-base/amazon.ami', 1, 'region.us-east-1')
      expect(@stub).to have_been_requested.once
    end
  end

  context "Stack" do
    before(:each) do
      @stub = stub_request(:any, /#{Atlas::URL}.*/).
        to_return(:body => File.new('./spec/atlas/state_response.json'), :status => 200)
      Atlas::reset_cache
    end

    it "is returned given a name and stack" do
      vpc_id = Atlas::get_output('vpc_id', 'unifio/example-vpc')
      expect(vpc_id).to eql('vpc-12345678')
    end

    it "is not returned if not found" do
      @stub = stub_request(:any, /#{Atlas::URL}.*/).
        to_return(:body => "", :status => 404)
      Atlas::reset_cache

      expect {
        Atlas::get_output('vpc_id', 'unifio/example-vpc')
      }.to raise_error(RuntimeError)
    end

    it "is not returned if it does not contain the requested output" do
      @stub = stub_request(:any, /#{Atlas::URL}.*/).
        to_return(:body => File.new('./spec/atlas/state_response.json'), :status => 200)
      Atlas::reset_cache

      expect {
        Atlas::get_output('test', 'unifio/example-vpc')
      }.to raise_error(RuntimeError)
    end

    it "caches multiple requests" do
      Atlas::get_output('vpc_id', 'unifio/example-vpc')
      Atlas::get_output('vpc_id', 'unifio/example-vpc')
      expect(@stub).to have_been_requested.once
    end
  end

  context "State store configuration" do
    it "is returned given valid store parameters" do
      config = Atlas::get_state_store({'name'=>'unifio/example-vpc'})
      expect(config).to eql('-backend-config="name=unifio/example-vpc" -backend=Atlas')
    end

    it "is not returned given invalid store parameters" do
      expect {
        config = Atlas::get_state_store({'path'=>'unifio/example-vpc'})
      }.to raise_error(RuntimeError)
    end
  end

  context "Key lookup" do
    context "Artifact" do
      before(:each) do
        @stub = stub_request(:any, /#{Atlas::URL}.*/).
          to_return(:body => File.new('./spec/atlas/artifact_response.json'), :status => 200)
        Atlas::reset_cache
        @type = 'artifact'
        @params = {
          'type' => 'atlas.artifact',
          'slug' => 'unifio/centos-base/amazon.ami',
          'version' => 1,
          'metadata' => 'region.us-west-2'
        }
      end

      it "verifies required parameters" do
        @params.delete('slug')
        expect {
          Atlas::lookup(@type,@params)
        }.to raise_error(RuntimeError)
      end

      it "is returned given all required parameters" do
        result = Atlas::lookup(@type,@params)
        expect(result).to eql('ami-23456789')
      end
    end

    context "State" do
      before(:each) do
        @stub = stub_request(:any, /#{Atlas::URL}.*/).
          to_return(:body => File.new('./spec/atlas/state_response.json'), :status => 200)
        Atlas::reset_cache
        @type = 'state'
        @params = {
          'type' => 'atlas.state',
          'key' => 'vpc_id',
          'stack' => 'unifio/vpc'
        }
      end

      it "verifies required parameters" do
        @params.delete('key')
        expect {
          Atlas::lookup(@type,@params)
        }.to raise_error(RuntimeError)
      end

      it "is returned given all required parameters" do
        result = Atlas::lookup(@type,@params)
        expect(result).to eql('vpc-12345678')
      end
    end
  end
end
