require 'rake'
require_relative '../../ruby/lib/tools/hiera.rb'
require_relative '../../ruby/lib/prometheus'

describe "Verify YAML" do

  before(:all) do
    @files = FileList["#{Prometheus::WORKSPACE}/**/*.yaml"]
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
