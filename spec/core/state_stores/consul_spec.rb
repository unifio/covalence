require 'spec_helper'
require_relative File.join(PrometheusUnifio::GEM_ROOT, 'core/state_stores/consul')

module PrometheusUnifio
  RSpec.describe Consul do
    it ".has_state_store?" do
      expect(described_class.has_state_store?).to be true
    end

    context "Key" do
      before(:each) do
        @stub = stub_request(:any, /#{Consul::URL}.*/).
        to_return(:body => File.new('./spec/fixtures/mock_responses/consul/key_response.json'), :status => 200)
        Consul::reset_cache
      end

      it "is returned given a name" do
        ex_ip = Consul::get_key('conf/example_ip')
        expect(ex_ip).to eql('172.16.2.238')
      end

      it "is not returned if not found" do
        @stub = stub_request(:any, /#{Consul::URL}.*/).
        to_return(:body => "", :status => 404)
        Consul::reset_cache

        expect {
          Consul::get_key('conf/example_ip')
        }.to raise_error(RuntimeError, /Unable to retrieve key/)
      end

      it "is not returned if it does not contain the requested value" do
        @stub = stub_request(:any, /#{Consul::URL}.*/).
        to_return(:body => File.new('./spec/fixtures/mock_responses/consul/empty_response.json'), :status => 200)
        Consul::reset_cache

        expect {
          Consul::get_key('conf/example_cidr')
        }.to raise_error(RuntimeError, /No results or unable to parse response/)
      end

      it "caches multiple requests" do
        2.times { Consul::get_key('conf/example_ip') }
        expect(@stub).to have_been_requested.once
      end
    end

    context "Stack" do
      before(:each) do
        @stub = stub_request(:any, /#{Consul::URL}.*/).
        to_return(:body => File.new('./spec/fixtures/mock_responses/consul/state_response.json'), :status => 200)
        Consul::reset_cache
      end

      it "is returned given a name and stack" do
        vpc_id = Consul::get_output('vpc_id', 'unifio/example-vpc')
        expect(vpc_id).to eql('vpc-12345678')
      end

      it "is not returned if not found" do
        @stub = stub_request(:any, /#{Consul::URL}.*/).
        to_return(:body => "", :status => 404)
        Consul::reset_cache

        expect {
          Consul::get_output('vpc_id', 'unifio/example-vpc')
        }.to raise_error(RuntimeError)
      end

      it "is not returned if it does not contain the requested output" do
        @stub = stub_request(:any, /#{Consul::URL}.*/).
        to_return(:body => File.new('./spec/fixtures/mock_responses/consul/state_response.json'), :status => 200)
        Consul::reset_cache

        expect {
          Consul::get_output('test', 'unifio/example-vpc')
        }.to raise_error(RuntimeError)
      end

      it "caches multiple requests" do
        Consul::get_output('vpc_id', 'unifio/example-vpc')
        Consul::get_output('vpc_id', 'unifio/example-vpc')
        expect(@stub).to have_been_requested.once
      end
    end

    context "State store configuration" do
      it "is returned given valid store parameters" do
        config = Consul::get_state_store({'name'=>'unifio/example-vpc'})
        expect(config).to eql('-backend-config="path=unifio/example-vpc" -backend=Consul')
      end

      it "is not returned given invalid store parameters" do
        expect {
          config = Consul::get_state_store({'path'=>'unifio/example-vpc'})
        }.to raise_error(RuntimeError)
      end
    end

    context "Key lookup" do
      context "Key" do
        before(:each) do
          @stub = stub_request(:any, /#{Consul::URL}.*/).
          to_return(:body => File.new('./spec/fixtures/mock_responses/consul/key_response.json'), :status => 200)
          Consul::reset_cache
          @type = 'key'
          @params = {
            'type' => 'consul.key',
            'key' => 'conf/example_ip'
          }
        end

        it "verifies required parameters" do
          @params.delete('key')
          expect {
            Consul::lookup(@type,@params)
          }.to raise_error(RuntimeError)
        end

        it "is returned given all required parameters" do
          result = Consul::lookup(@type,@params)
          expect(result).to eql('172.16.2.238')
        end
      end

      context "State" do
        before(:each) do
          @stub = stub_request(:any, /#{Consul::URL}.*/).
          to_return(:body => File.new('./spec/fixtures/mock_responses/consul/state_response.json'), :status => 200)
          Consul::reset_cache
          @type = 'state'
          @params = {
            'type' => 'consul.state',
            'key' => 'vpc_id',
            'stack' => 'unifio/vpc'
          }
        end

        it "verifies required parameters" do
          @params.delete('key')
          expect {
            Consul::lookup(@type,@params)
          }.to raise_error(RuntimeError)
        end

        it "is returned given all required parameters" do
          result = Consul::lookup(@type,@params)
          expect(result).to eql('vpc-12345678')
        end
      end

      it "invalid type" do
        expect{ Consul.lookup('invalid', {}) }.to raise_error(RuntimeError, /does not support the 'invalid' lookup type/)
      end
    end
  end
end
