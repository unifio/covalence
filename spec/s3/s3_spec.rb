require_relative '../../ruby/lib/tools/s3.rb'
require 'aws-sdk'

RSpec.describe S3 do

  context "Key" do
    before(:all) do
      Aws.config[:s3] = {
        stub_responses: {
          get_object: { body: File.new('./spec/s3/key_response.json') }
        }
      }
      @client = S3::Client.new(region: 'us-east-1')
    end

    before(:each) do
      @client::reset_cache
    end

    it "is returned given a bucket, document and key name" do
      ex_ip = @client::get_key('unifio-config','config','example_ip')
      expect(ex_ip).to eql('172.16.2.238')
    end

    it "is not returned if it does not contain the requested value" do
      expect {
        @client::get_key('unifio-config','config','doesnotexist')
      }.to raise_error(RuntimeError)
    end

    it "caches multiple requests" do
      @client::get_key('unifio-config','config','example_ip')
      @client::get_key('unifio-config','config','example_ip')
      cache = @client.get_cache
      result = "{\"unifio-config\"=>{\"config\"=>\"{\\n  \\\"example_ip\\\": \\\"172.16.2.238\\\"\\n}\\n\"}}"
      expect(cache).to eql(result)
    end

    it "clears cache" do
      cache = @client.get_cache
      expect(cache).to eql("{}")
    end
  end

  context "Stack" do
    before(:all) do
      Aws.config[:s3] = {
        stub_responses: {
          get_object: { body: File.new('./spec/s3/state_response.json') }
        }
      }
      @client = S3::Client.new(region: 'us-east-1')
    end

    before(:each) do
      @client::reset_cache
    end

    it "is returned given a bucket, document and key name" do
      vpc_id = @client::get_key('unifio-config','config','vpc_id')
      expect(vpc_id).to eql('vpc-12345678')
    end
  end

  context "State store configuration" do
    it "is returned given valid store parameters" do
      config = S3::get_state_store({'name'=>'unifio/example-vpc','bucket'=>'unifio-terraform'})
      expect(config).to eql('-backend=s3 -backend-config="key=unifio/example-vpc/terraform.tfstate" -backend-config="bucket=unifio-terraform"')
    end

    it "is not returned given invalid store parameters" do
      expect {
        config = S3::get_state_store({'path'=>'unifio/example-vpc'})
      }.to raise_error(RuntimeError)
    end
  end

  context "Key lookup" do
    context "Key" do
      before(:all) do
        Aws.config[:s3] = {
          stub_responses: {
            get_object: { body: File.new('./spec/s3/key_response.json') }
          }
        }
        @client = S3::Client.new(region: 'us-east-1')
      end

      before(:each) do
        @client::reset_cache
        @type = 'key'
        @params = {
          'bucket' => 'unifio-config',
          'document' => 'config',
          'key' => 'example_ip'
        }
      end

      it "verifies required parameters" do
        @params.delete('key')
        expect {
          S3::lookup(@type,@params)
        }.to raise_error(RuntimeError)
      end

      it "is returned given all required parameters" do
        result = S3::lookup(@type,@params)
        expect(result).to eql('172.16.2.238')
      end
    end

    context "State" do
      before(:all) do
        Aws.config[:s3] = {
          stub_responses: {
            get_object: { body: File.new('./spec/s3/state_response.json') }
          }
        }
        @client = S3::Client.new(region: 'us-east-1')
      end

      before(:each) do
        @client::reset_cache
        @type = 'state'
        @params = {
          'bucket' => 'unifio-config',
          'document' => 'config',
          'key' => 'vpc_id'
        }
      end

      it "verifies required parameters" do
        @params.delete('key')
        expect {
          S3::lookup(@type,@params)
        }.to raise_error(RuntimeError)
      end

      it "is returned given all required parameters" do
        result = S3::lookup(@type,@params)
        expect(result).to eql('vpc-12345678')
      end
    end
  end
end
