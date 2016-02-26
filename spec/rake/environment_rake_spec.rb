require_relative '../../ruby/lib/environment.rb'
require_relative '../../ruby/lib/tools/terraform.rb'
require_relative '../shared_contexts/rake.rb'

describe "rspec:myapp:verify" do
  include_context "rake"

  it "cleans the workspace" do
    expect_any_instance_of(Terraform::Stack).to receive(:clean)
    subject.invoke
  end

  it "gets Terraform modules" do
    expect_any_instance_of(Terraform::Stack).to receive(:get)
    subject.invoke
  end

  it "executes a plan" do
    expect_any_instance_of(Terraform::Stack).to receive(:plan).with("-var label=test -input=false -module-depth=-1 -target=test")
    subject.invoke
  end
end

describe "rspec:myapp:plan" do
  include_context "rake"

  it "cleans the workspace" do
    expect_any_instance_of(Terraform::Stack).to receive(:clean)
    subject.invoke
  end

  it "configures remote state" do
    expect_any_instance_of(Terraform::Stack).to receive(:remote_config)
    subject.invoke
  end

  it "gets Terraform modules" do
    expect_any_instance_of(Terraform::Stack).to receive(:get)
    subject.invoke
  end

  it "executes a plan" do
    expect_any_instance_of(Terraform::Stack).to receive(:plan).with("-var label=test -input=false -module-depth=-1 -target=test")
    subject.invoke
  end
end

describe "rspec:myapp:plan_destroy" do
  include_context "rake"

  it "cleans the workspace" do
    expect_any_instance_of(Terraform::Stack).to receive(:clean)
    subject.invoke
  end

  it "gets Terraform modules" do
    expect_any_instance_of(Terraform::Stack).to receive(:get)
    subject.invoke
  end

  it "executes a plan" do
    expect_any_instance_of(Terraform::Stack).to receive(:plan).with("-var label=test -destroy -input=false -module-depth=-1 -target=test")
    subject.invoke
  end
end

describe "rspec:myapp:apply" do
  include_context "rake"

  it "cleans the workspace" do
    expect_any_instance_of(Terraform::Stack).to receive(:clean)
    subject.invoke
  end

  it "configures remote state" do
    expect_any_instance_of(Terraform::Stack).to receive(:remote_config)
    subject.invoke
  end

  it "gets Terraform modules" do
    expect_any_instance_of(Terraform::Stack).to receive(:get)
    subject.invoke
  end

  it "executes a plan" do
    expect_any_instance_of(Terraform::Stack).to receive(:plan).with("-var label=test -input=false -module-depth=-1 -target=test")
    subject.invoke
  end

  it "executes an apply" do
    expect_any_instance_of(Terraform::Stack).to receive(:apply).with("-var label=test -target=test")
    subject.invoke
  end
end

describe "rspec:myapp:destroy" do
  include_context "rake"

  it "cleans the workspace" do
    expect_any_instance_of(Terraform::Stack).to receive(:clean)
    subject.invoke
  end

  it "configures remote state" do
    expect_any_instance_of(Terraform::Stack).to receive(:remote_config)
    subject.invoke
  end

  it "gets Terraform modules" do
    expect_any_instance_of(Terraform::Stack).to receive(:get)
    subject.invoke
  end

  it "executes a plan" do
    expect_any_instance_of(Terraform::Stack).to receive(:plan).with("-var label=test -destroy -input=false -module-depth=-1 -target=test")
    subject.invoke
  end

  it "executes a destroy" do
    expect_any_instance_of(Terraform::Stack).to receive(:destroy).with("-var label=test -target=test")
    subject.invoke
  end
end

describe "rspec:myapp:sync" do
  include_context "rake"

  it "cleans the workspace" do
    expect_any_instance_of(Terraform::Stack).to receive(:clean)
    subject.invoke
  end

  it "configures remote state" do
    expect_any_instance_of(Terraform::Stack).to receive(:remote_config)
    subject.invoke
  end
end
