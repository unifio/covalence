require 'spec_helper'
require_relative File.join(Covalence::GEM_ROOT, 'core/state_stores/atlas')

module Covalence
  RSpec.describe Atlas do

    context "Search" do
      before(:all) do
        WebMock.allow_net_connect!
      end

      after(:all) do
        WebMock.disable_net_connect!
      end

      it "is returned given a slug, version and key w/o metadata filtering" do
        key = Atlas::get_artifact('yungsang/boot2docker/vagrant.box', 29, 'provider')
        expect(key).to eql('virtualbox')
      end

      it "is returned given a slug, version and key w/ metadata filtering" do
        key = Atlas::get_artifact('yungsang/boot2docker/vagrant.box', 29, 'version', metadata: {'provider'=>'virtualbox'})
        expect(key).to eql('1.4.1')
      end

      it "is returned given a slug, version and key w/ metadata filtering where the record to be returned is not latest" do
        key = Atlas::get_artifact('yungsang/boot2docker/vagrant.box', 'latest', 'url', metadata: {'version'=>'1.3.7'})
        expect(key).to eql('https://github.com/YungSang/boot2docker-vagrant-box/releases/download/yungsang%2Fv1.3.7/boot2docker-virtualbox.box')
      end

      it "is returned given a slug and key w/ version set to latest" do
        key = Atlas::get_artifact('yungsang/boot2docker/vagrant.box', 'latest', 'provider')
        expect(key).to eql('virtualbox')
      end
    end

    context "Artifact" do
      before(:each) do
        @stub = stub_request(:any, /#{Atlas::URL}.*/).
        to_return(:body => File.new('./spec/fixtures/mock_responses/atlas/artifact_response.json'), :status => 200)
        Atlas::reset_cache
      end

      it "is returned given a slug, version and key" do
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

      it "is not returned if it does not contain the requested key" do
        @stub = stub_request(:any, /#{Atlas::URL}.*/).
        to_return(:body => File.new('./spec/fixtures/mock_responses/atlas/artifact_response.json'), :status => 200)
        Atlas::reset_cache

        expect {
          Atlas::get_artifact('unifio/centos-base/amazon.ami', 1, 'region.us-west-1')
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
        to_return(:body => File.new('./spec/fixtures/mock_responses/atlas/state_response.json'), :status => 200)
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
        to_return(:body => File.new('./spec/fixtures/mock_responses/atlas/state_response.json'), :status => 200)
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
        output = <<-CONF
terraform {
  backend "atlas" {
    name = "unifio/example-vpc"
  }
}
CONF
        expect(config).to eql(output)
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
          to_return(:body => File.new('./spec/fixtures/mock_responses/atlas/artifact_response.json'), :status => 200)
          Atlas::reset_cache
          @type = 'artifact'
          @params = {
            'type' => 'atlas.artifact',
            'slug' => 'unifio/centos-base/amazon.ami',
            'version' => 1,
            'key' => 'region.us-west-2'
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
          to_return(:body => File.new('./spec/fixtures/mock_responses/atlas/state_response.json'), :status => 200)
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

      it "invalid type" do
        expect{ Atlas.lookup('invalid', {}) }.to raise_error(RuntimeError, /does not support the 'invalid' lookup type/)
      end
    end
  end
end
