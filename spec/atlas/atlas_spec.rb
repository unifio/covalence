require_relative '../../ruby/lib/tools/atlas.rb'
require 'webmock/rspec'

RSpec.describe Atlas do

  context "Artifact" do
    before(:each) do
      @stub = stub_request(:any, /#{Atlas::URL}.*/).
        to_return(:body => File.new('./spec/atlas/artifact_response.json'), :status => 200)
      Atlas::reset_cache
    end

    it "is returned given a slug, version and region" do
      ami_id = Atlas::get_artifact('unifio/centos-base/amazon.ami', 1, 'us-east-1')
      expect(ami_id).to eql('ami-12345678')
    end

    it "is not returned if not found" do
      @stub = stub_request(:any, /#{Atlas::URL}.*/).
        to_return(:body => "", :status => 404)
      Atlas::reset_cache

      expect {
        Atlas::get_artifact('unifio/centos-base/amazon.ami', 1, 'us-east-1')
      }.to raise_error(RuntimeError)
    end

    it "is not returned if it does not contain the requested metadata" do
      @stub = stub_request(:any, /#{Atlas::URL}.*/).
        to_return(:body => File.new('./spec/atlas/artifact_response.json'), :status => 200)
      Atlas::reset_cache

      expect {
        Atlas::get_artifact('unifio/centos-base/amazon.ami', 20, 'us-west-1')
      }.to raise_error(RuntimeError)
    end

    it "caches multiple requests" do
      Atlas::get_artifact('unifio/centos-base/amazon.ami', 1, 'us-east-1')
      Atlas::get_artifact('unifio/centos-base/amazon.ami', 1, 'us-east-1')
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
    it "is returned given a stack name" do
      config = Atlas::get_state_store('unifio/example-vpc')
      expect(config).to eql('-backend-config="name=unifio/example-vpc" -backend=Atlas')
    end
  end
end
