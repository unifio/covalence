require_relative '../../ruby/lib/environment.rb'
require_relative '../../ruby/lib/tools/terraform.rb'

RSpec.describe Environment do

  before(:all) do
    @env_rdr = EnvironmentReader.new
    @env = @env_rdr.environments.first
    @stack = @env.stacks[0]
    @store = @stack.state_stores.first
  end

  context "Environment Reader" do
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

  context "Environment" do
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

  context "Stack" do
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

    it "does accept empty args" do
      stack = @env.stacks[1]
      expect(stack.args).to eql('')
    end

    it "does accept empty vars" do
      stack = @env.stacks[1]
      expect(stack.inputs).to eql([])
    end

    it "does accept empty targets" do
      stack = @env.stacks[1]
      expect(stack.contexts).to be_instance_of Array
    end

    it "does return the path to the stack module when explicitly specified" do
      stack = @env.stacks[1]
      expect(stack.tf_module).to eql('myapp2')
    end

    it "does yield state stores" do
      expect(@stack.state_stores).to be_instance_of Array
    end

    it "does yield state store objects" do
      expect(@store).to be_instance_of Environment::Stack::StateStore
    end

    it "does yield args" do
      expect(@stack.args).to eql('-no-color')
    end

    it "does yield inputs" do
      stack = @env.stacks[2]
      expect(stack.inputs).to be_instance_of Array
    end

    it "does yield input objects" do
      stack = @env.stacks[2]
      input = stack.inputs.first
      expect(input).to be_instance_of Environment::Stack::Input
    end

    it "does yield targets" do
      expect(@stack.contexts).to be_instance_of Array
    end

    it "does yield context objects" do
      input = @stack.contexts.first
      expect(input).to be_instance_of Environment::Stack::Context
    end
  end

  context "State Store" do
    it "does return state store name as a symbol" do
      expect(@store.to_sym.to_s).to eql('example/myapp')
    end

    it "does return state store name as a string" do
      expect(@store.to_s).to eql('example/myapp')
    end

    it "does return state store backend" do
      expect(@store.backend).to eql('Atlas')
    end

    it "does retrieve the state store configuration string" do
      expect(Atlas).to receive(:get_state_store).with({'name'=>'example/myapp'})
      @store.get_config
    end
  end

  context "Input" do
    before(:all) do
      stack = @env.stacks[2]
      @input = stack.inputs.first
      @lookup = stack.inputs[1]
    end

    it "does return input name as a symbol" do
      expect(@input.to_sym.to_s).to eql('label')
    end

    it "does return input name as a string" do
      expect(@input.to_s).to eql('label')
    end

    it "does return that a local key is local" do
      expect(@input.is_local?).to eql(true)
    end

    it "does return the local backend for a local key" do
      expect(@input.backend).to eql('local')
    end

    it "does return the key type for a local key" do
      expect(@input.type).to eql('key')
    end

    it "does return the value for a local key" do
      expect(@input.value).to eql('test')
    end

    it "does return that a remote key is not local" do
      expect(@lookup.is_local?).to eql(false)
    end

    it "does return the backend for a remote key" do
      expect(@lookup.backend).to eql('Atlas')
    end

    it "does return the key type for a remote key" do
      expect(@lookup.type).to eql('artifact')
    end

    it "does return the value for a non-local key" do
      expect(@lookup.value).to eql({'type'=>'atlas.artifact','slug'=>'unifio/centos-base/amazon.ami','version'=>1,'metadata'=>'region.us-west-2'})
    end
  end

  context "Context" do
    before(:all) do
      stack = @env.stacks[0]
      @context = stack.contexts.first
    end

    it "does return context name as a symbol" do
      expect(@context.to_sym.to_s).to eql('az0')
    end

    it "does return context name as a string" do
      expect(@context.to_s).to eql('az0')
    end

    it "does return context namespace as a string" do
      expect(@context.namespace).to eql('az0:')
    end

    it "does return empty string for the context namespace when name is an empty string" do
      stack = @env.stacks[1]
      context = stack.contexts.first

      expect(context.namespace).to eql('')
    end

    it "does return the value" do
      expect(@context.value).to eql(['module.az0'])
    end
  end

  context "Input Reader" do
    it "does return combined configuration hash" do
      stub_request(:any, /#{Atlas::URL}.*/).
        to_return(:body => File.new('./spec/atlas/artifact_response.json'), :status => 200)
      stack = @env.stacks[2]
      inputs = InputReader.new(stack)

      expect(inputs.to_h).to eql({'label'=>'test','ami'=>'ami-23456789'})
    end
  end
end
