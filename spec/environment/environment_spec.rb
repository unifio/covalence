require_relative '../../ruby/lib/environment.rb'
require_relative '../../ruby/lib/tools/terraform.rb'

RSpec.describe Environment do

  before(:all) do
    @env_rdr = EnvironmentReader.new
    @env = @env_rdr.environments.first
    @stack = @env.stacks[0]
    @store = @stack.state_stores.first
  end

  context "test environment reader" do

    it "can read configuration" do
      expect(@env_rdr).to be_instance_of EnvironmentReader
    end

    it "does yield environments" do
      expect(@env_rdr.environments).to be_instance_of Array
    end

    it "does yield environment objects" do
      expect(@env).to be_instance_of Environment
    end
  end

  context "test environments" do
    it "does return environment name as a symbol" do
      expect(@env.to_sym.to_s).to eql('rspec')
    end

    it "does return environment name as a string" do
      expect(@env.to_s).to eql('rspec')
    end

    it "does yield stacks" do
      expect(@env_rdr.environments.first.stacks).to be_instance_of Array
    end

    it "does yield stack objects" do
      expect(@stack).to be_instance_of Environment::Stack
    end
  end

  context "test stacks" do
    it "does return stack name as a symbol" do
      expect(@stack.to_sym.to_s).to eql('myapp')
    end

    it "does return stack name as a string" do
      expect(@stack.to_s).to eql('myapp')
    end

    it "does return stack full name as a string" do
      expect(@stack.full_name).to eql('rspec-myapp')
    end

    it "does return the path to the stack module" do
      expect(@stack.tf_module).to eql('myapp')
    end

    it "does return the path to the stack module when explicitly specified" do
      stack = @env.stacks[1]
      expect(stack.tf_module).to eql('myapp2')
    end

    it "does yield state stories" do
      expect(@stack.state_stores).to be_instance_of Array
    end

    it "does yield state store objects" do
      expect(@store).to be_instance_of Environment::StateStore
    end
  end

  context "test state stores" do
    it "does retrun state store name as a symbol" do
      expect(@store.to_sym.to_s).to eql('example/myapp')
    end

    it "does return state store name as a string" do
      expect(@store.to_s).to eql('example/myapp')
    end

    it "does retrieve the state store configuration string" do
      expect(Atlas).to receive(:get_state_store).with('example/myapp')
      @store.config
    end
  end
end
