require_relative '../../ruby/lib/prometheus.rb'

RSpec.describe Prometheus do
  it "WORKSPACE exists" do
    expect(File).to exist(Prometheus::WORKSPACE)
  end

  it "CONFIG exists" do
    expect(File).to exist(Prometheus::CONFIG)
  end

  it "RSPEC exists" do
    expect(File).to exist(Prometheus::RSPEC)
  end

  it "PACKER exists" do
    expect(File).to exist(Prometheus::PACKER)
  end

  it "TERRAFORM exists" do
    expect(File).to exist(Prometheus::TERRAFORM)
  end
end
