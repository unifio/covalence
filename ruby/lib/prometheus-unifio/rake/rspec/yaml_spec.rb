require 'rake'
require_relative '../../../prometheus-unifio'
require_relative '../../../tools/hiera.rb'

describe "Verify YAML" do

  before(:all) do
    @files = FileList["#{PrometheusUnifio::WORKSPACE}/**/*.yaml"]
    @files.reject! { |f| File.directory?(f) }
    # Exclude Prometheus test data
    @files.reject! { |f| File.basename(f) == 'invalid.yaml' }
    @syntax = HieraDB::Syntax.new
  end

  it 'passes syntax check' do
    errors = @syntax.check_yaml(@files)
    expect(errors).to be_empty
  end
end
