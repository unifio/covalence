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
    expect(@stack).to receive(:run_rake_cmd).with('remote', 'config')
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

  it "executes terraform commands with custom settings" do
    @cmd_test = Stack.new(@stack_dir, dir: @parent_dir, env: "TEST=thisisatest", img: "", cmd: "/usr/local/bin/terraform", stub: "false")
    cmd = "TEST=thisisatest /usr/local/bin/terraform plan"
    expect(Rake::AltSystem).to receive(:system).with(cmd).and_return(true)
    @cmd_test.plan
  end

  it "executes terraform commands within a container" do
    @cmd_test = Stack.new(@stack_dir, dir: @parent_dir, env: "", img: "unifio/terraform:latest", cmd: "docker run --rm", stub: "false")
    cmd = "docker run --rm -v #{@parent_dir}:/data -w /data/#{@stack_dir} unifio/terraform:latest plan"
    expect(Rake::AltSystem).to receive(:system).with(cmd).and_return(true)
    @cmd_test.plan
  end

  it "cleans up existing state data from the given stack directory" do
    @cmd_test = Stack.new(@stack_dir, dir: @parent_dir, env: "", img: "", cmd: "", stub: "false")
    cmd = "/bin/sh -c \"rm -fr .terraform *.tfstate*\""
    expect(Rake::AltSystem).to receive(:system).with(cmd).and_return(true)
    @cmd_test.clean
  end

  it "cleans up existing state data from the given stack directory within a container" do
    @cmd_test = Stack.new(@stack_dir, dir: @parent_dir, env: "", img: "unifio/terraform:latest", cmd: "docker run --rm", stub: "false")
    cmd = "docker run --rm -v #{@parent_dir}:/data -w /data/#{@stack_dir} --entrypoint=\"/bin/sh\" unifio/terraform:latest -c \"rm -fr .terraform *.tfstate*\""
    expect(Rake::AltSystem).to receive(:system).with(cmd).and_return(true)
    @cmd_test.clean
  end

  it "processes Terraform inputs" do
    vars = {
      'environment' => 'testing'
    }

    inputs = @stack.parse_vars(vars)
    expect(inputs).to eql('-var environment=testing')
  end

  it "processes empty inputs" do
    vars = {}

    inputs = @stack.parse_vars(vars)
    expect(inputs).to eql('')
  end

  it "processes Terraform targets" do
    targets = [
      'module.az0'
    ]

    inputs = @stack.parse_targets(targets)
    expect(inputs).to eql('-target=module.az0')
  end

  it "processes empty targets" do
    targets = []

    inputs = @stack.parse_targets(targets)
    expect(inputs).to eql('')
  end
end
