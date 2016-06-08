require_relative '../../ruby/lib/prometheus-unifio.rb'

RSpec.describe PrometheusUnifio do
  it "WORKSPACE exists" do
    expect(File).to exist(PrometheusUnifio::WORKSPACE)
  end

  it "CONFIG exists" do
    expect(File).to exist(PrometheusUnifio::CONFIG)
  end

  it "PACKER exists" do
    expect(File).to exist(PrometheusUnifio::PACKER)
  end

  it "TERRAFORM exists" do
    expect(File).to exist(PrometheusUnifio::TERRAFORM)
  end
end
