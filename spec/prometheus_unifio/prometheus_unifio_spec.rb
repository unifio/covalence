require 'spec_helper'

RSpec.describe PrometheusUnifio do
  it "WORKSPACE exists" do
    expect(File).to exist(described_class::WORKSPACE)
  end

  it "CONFIG exists" do
    expect(File).to exist(described_class::CONFIG)
  end

  it "PACKER exists" do
    expect(File).to exist(described_class::PACKER)
  end

  it "TERRAFORM exists" do
    expect(File).to exist(described_class::TERRAFORM)
  end
end
