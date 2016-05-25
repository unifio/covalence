require 'rake'
require_relative '../../ruby/lib/tools/hiera.rb'
require_relative '../../ruby/lib/prometheus'

describe "Verify YAML" do

  before(:all) do
    @files = FileList["#{Prometheus::WORKSPACE}/**/*.yaml"]
    @files.reject! { |f| File.directory?(f) }
    @c = HieraDB::Syntax.new
  end

  it 'passes syntax check' do
    errors = @c.check(@files)
    expect(errors).to be_empty
  end
end
