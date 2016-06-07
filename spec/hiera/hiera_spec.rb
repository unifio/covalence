require_relative '../../ruby/lib/prometheus-unifio.rb'
require_relative '../../ruby/lib/tools/hiera.rb'

include HieraDB

describe Client do

  before(:all) do
    @client = HieraDB::Client.new(PrometheusUnifio::CONFIG)
  end

  it "can lookup without a scope defined" do
    response = @client.lookup('environments')

    expect(response).to eql({"example"=>["myapp", "module_test", "artifact_test"]})
  end

  it "can lookup with a scope defined" do
    @client.set_scope('example','myapp')
    response = @client.lookup('myapp::vars')

    expect(response).to eql({'label'=>'test'})
  end

  it "can perform an array lookup" do
    @client.set_scope('example','artifact_test')
    response = @client.array_lookup('myapp2::array_test')

    expect(response).to eql(['stack_data','environment_data'])
  end

  it "array lookup only returns unqiue results" do
    @client.set_scope('example','artifact_test')
    response = @client.array_lookup('myapp2::array_test_1')

    expect(response).to eql(['dedup'])
  end

  it "can perform an array lookup on string values" do
    @client.set_scope('example','artifact_test')
    response = @client.array_lookup('myapp2::array_test_2')

    expect(response).to eql(['stack_data','environment_data'])
  end

  it "can perform an array lookup on mixed values" do
    @client.set_scope('example','artifact_test')
    response = @client.array_lookup('myapp2::array_test_3')

    expect(response).to eql(['stack_data','environment_data'])
  end

  it "can perform a hash lookup" do
    @client.set_scope('example','artifact_test')
    response = @client.hash_lookup('myapp2::hash_test')

    expect(response).to eql({'key' => 'stack'})
  end

  it "hash lookup returns all unique keys" do
    @client.set_scope('example','artifact_test')
    response = @client.hash_lookup('myapp2::hash_test_1')

    expect(response).to eql({'key' => 'stack','key1' => 'environment'})
  end

  it "hash lookup merges nested hashes" do
    @client.set_scope('example','artifact_test')
    response = @client.hash_lookup('myapp2::hash_test_2')

    expect(response).to eql({'ami' => { 'metadata' => 'region.us-west-2', 'version' => 'latest' }})
  end
end

describe Syntax do

  before(:each) do
    @client = HieraDB::Syntax.new
  end

  it "checks YAML" do
    files = FileList["#{PrometheusUnifio::WORKSPACE}/spec/hiera/data/valid.yaml"]
    errors = @client.check_yaml(files)
    expect(errors).to be_empty
  end

  it "detects invalid YAML" do
    files = FileList["#{PrometheusUnifio::WORKSPACE}/spec/hiera/data/invalid.yaml"]
    errors = @client.check_yaml(files)
    expect(errors).to_not be_empty
  end
end
