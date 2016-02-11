require 'tmpdir'
require_relative '../../ruby/lib/tools/terraform.rb'

include Terraform

describe Stack do

  before(:each) do
    dir = Dir.mktmpdir
    @parent_dir = File.dirname(dir)
    @stack_dir = File.basename(dir)
    @stack = Stack.new(@stack_dir, dir: @parent_dir)
  end

  it "returns a stack given a directory that exists" do
    expect(@stack).to be_a(Stack)
  end

  it "raises an exception if the given directory does not exist" do
    expect { Stack.new('doesnotexist') }.to raise_error(RuntimeError)
  end

  it "executes terraform remote config" do
    expect(@stack).to receive(:run_rake_cmd).with('remote', 'config ')
    @stack.remote_config
  end

  it "executes terraform remote pull" do
    expect(@stack).to receive(:run_rake_cmd).with('remote', 'pull')
    @stack.remote_pull
  end

  it "executes terraform remote push" do
    expect(@stack).to receive(:run_rake_cmd).with('remote', 'push')
    @stack.remote_push
  end

  it "executes terraform plan" do
    expect(@stack).to receive(:run_rake_cmd).with('plan', '')
    @stack.plan
  end

  it "executes terraform apply" do
    expect(@stack).to receive(:run_rake_cmd).with('apply', '')
    @stack.apply
  end

  it "executes terraform destroy" do
    expect(@stack).to receive(:run_rake_cmd).with('destroy', '')
    @stack.destroy
  end

  it "executes terraform commands with defaults settings" do
    cmd = "TF_VAR_atlas_token=$ATLAS_TOKEN terraform plan -input=false -module-depth=-1"
    expect(Rake::AltSystem).to receive(:system).with(cmd).and_return(true)
    @stack.plan("-input=false -module-depth=-1")
  end

  it "executes terraform commands with custom settings" do
    @cmd_test = Stack.new(@stack_dir, dir: @parent_dir, env: "TEST=thisisatest", cmd: "docker run --rm unifio/terraform:latest")
    cmd = "TEST=thisisatest docker run --rm unifio/terraform:latest plan "
    expect(Rake::AltSystem).to receive(:system).with(cmd).and_return(true)
    @cmd_test.plan
  end

  it "cleans up existing state data from the given stack directory" do
    cmd = "rm -fr .terraform *.tfstate*"
    expect(Rake::AltSystem).to receive(:system).with(cmd).and_return(true)
    @stack.clean
  end

  it "processes Terraform inputs" do
    vars = {
      'environment' => 'testing'
    }

    inputs = @stack.parse_vars(vars)
    expect(inputs).to eql('-var environment=testing')
  end
end
