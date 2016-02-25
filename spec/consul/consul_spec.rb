require_relative '../../ruby/lib/tools/consul.rb'
require 'webmock/rspec'

RSpec.describe Consul do

  context "Key" do
    before(:each) do
      @stub = stub_request(:any, /#{Consul::URL}.*/).
        to_return(:body => File.new('./spec/consul/key_response.json'), :status => 200)
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
      }.to raise_error(RuntimeError)
    end

    it "is not returned if it does not contain the requested value" do
      @stub = stub_request(:any, /#{Consul::URL}.*/).
        to_return(:body => File.new('./spec/consul/empty_response.json'), :status => 200)
      Consul::reset_cache

      expect {
        Consul::get_key('conf/example_cidr')
      }.to raise_error(RuntimeError)
    end

    it "caches multiple requests" do
      Consul::get_key('conf/example_ip')
      Consul::get_key('conf/example_ip')
      expect(@stub).to have_been_requested.once
    end
  end

  context "Stack" do
    before(:each) do
      @stub = stub_request(:any, /#{Consul::URL}.*/).
        to_return(:body => File.new('./spec/consul/state_response.json'), :status => 200)
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
        to_return(:body => File.new('./spec/consul/state_response.json'), :status => 200)
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
          to_return(:body => File.new('./spec/consul/key_response.json'), :status => 200)
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
          to_return(:body => File.new('./spec/consul/state_response.json'), :status => 200)
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
  end
end
