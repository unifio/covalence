require_relative '../../ruby/lib/environment.rb'
require_relative '../../ruby/lib/tools/terraform.rb'
require_relative '../shared_contexts/rake.rb'

describe "rspec:myapp:clean" do
  include_context "rake"

  it "cleans the workspace" do
    expect_any_instance_of(Terraform::Stack).to receive(:clean)
    subject.invoke
  end
end

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
    expect_any_instance_of(Terraform::Stack).to receive(:plan).with("-var label=test -input=false -module-depth=-1 -no-color")
    subject.invoke
  end
end

describe "rspec:myapp:az0:plan" do
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
    expect_any_instance_of(Terraform::Stack).to receive(:plan).with("-var label=test -input=false -module-depth=-1 -no-color -target=module.az0")
    subject.invoke
  end
end

describe "rspec:myapp:az0:plan_destroy" do
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
    expect_any_instance_of(Terraform::Stack).to receive(:plan).with("-var label=test -destroy -input=false -module-depth=-1 -no-color -target=module.az0")
    subject.invoke
  end
end

describe "rspec:myapp:az0:apply" do
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
    expect_any_instance_of(Terraform::Stack).to receive(:plan).with("-var label=test -input=false -module-depth=-1 -no-color -target=module.az0")
    subject.invoke
  end

  it "executes an apply" do
    expect_any_instance_of(Terraform::Stack).to receive(:apply).with("-var label=test -no-color -target=module.az0")
    subject.invoke
  end
end

describe "rspec:myapp:az0:destroy" do
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
    expect_any_instance_of(Terraform::Stack).to receive(:plan).with("-var label=test -destroy -input=false -module-depth=-1 -no-color -target=module.az0")
    subject.invoke
  end

  it "executes a destroy" do
    expect_any_instance_of(Terraform::Stack).to receive(:destroy).with("-var label=test -no-color -target=module.az0")
    subject.invoke
  end
end

describe "rspec:myapp:az1:plan" do
  include_context "rake"

  it "executes a plan" do
    expect_any_instance_of(Terraform::Stack).to receive(:plan).with("-var label=test -input=false -module-depth=-1 -no-color -target=module.az1 -target=module.common.aws_eip.myapp")
    subject.invoke
  end
end

describe "rspec:myapp:az1:plan_destroy" do
  include_context "rake"

  it "executes a plan" do
    expect_any_instance_of(Terraform::Stack).to receive(:plan).with("-var label=test -destroy -input=false -module-depth=-1 -no-color -target=module.az1 -target=module.common.aws_eip.myapp")
    subject.invoke
  end
end

describe "rspec:myapp:az1:apply" do
  include_context "rake"

  it "executes a plan" do
    expect_any_instance_of(Terraform::Stack).to receive(:plan).with("-var label=test -input=false -module-depth=-1 -no-color -target=module.az1 -target=module.common.aws_eip.myapp")
    subject.invoke
  end

  it "executes an apply" do
    expect_any_instance_of(Terraform::Stack).to receive(:apply).with("-var label=test -no-color -target=module.az1 -target=module.common.aws_eip.myapp")
    subject.invoke
  end
end

describe "rspec:myapp:az1:destroy" do
  include_context "rake"

  it "executes a plan" do
    expect_any_instance_of(Terraform::Stack).to receive(:plan).with("-var label=test -destroy -input=false -module-depth=-1 -no-color -target=module.az1 -target=module.common.aws_eip.myapp")
    subject.invoke
  end

  it "executes a destroy" do
    expect_any_instance_of(Terraform::Stack).to receive(:destroy).with("-var label=test -no-color -target=module.az1 -target=module.common.aws_eip.myapp")
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

describe "rspec:module_test:plan" do
  include_context "rake"

  it "executes a plan" do
    expect_any_instance_of(Terraform::Stack).to receive(:plan).with("-input=false -module-depth=-1")
    subject.invoke
  end
end

describe "rspec:module_test:plan_destroy" do
  include_context "rake"

  it "executes a plan" do
    expect_any_instance_of(Terraform::Stack).to receive(:plan).with("-destroy -input=false -module-depth=-1")
    subject.invoke
  end
end

describe "rspec:module_test:apply" do
  include_context "rake"

  it "executes a plan" do
    expect_any_instance_of(Terraform::Stack).to receive(:plan).with("-input=false -module-depth=-1")
    subject.invoke
  end

  it "executes an apply" do
    expect_any_instance_of(Terraform::Stack).to receive(:apply).with("")
    subject.invoke
  end
end

describe "rspec:module_test:destroy" do
  include_context "rake"

  it "executes a plan" do
    expect_any_instance_of(Terraform::Stack).to receive(:plan).with("-destroy -input=false -module-depth=-1")
    subject.invoke
  end

  it "executes a destroy" do
    expect_any_instance_of(Terraform::Stack).to receive(:destroy).with("")
    subject.invoke
  end
end
