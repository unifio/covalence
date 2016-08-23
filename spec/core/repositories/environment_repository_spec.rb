require 'spec_helper'
require_relative File.join(PrometheusUnifio::GEM_ROOT, 'core/repositories/environment_repository')

module PrometheusUnifio
  RSpec.describe EnvironmentRepository do
    describe ".all" do
      pending
    end
  end
end


#RSpec.describe EnvironmentRepository do

  #before(:all) do
    #@env_repo = EnvironmentRepository
    #@env = @env_repo.all.first
    #@stack = @env.stacks[0]
    #@store = @stack.state_stores.first
  #end

  #context "Stack" do
    # Environment Repository unit test
    #it "does return the path to the stack module" do
      #expect(@stack.tf_module).to eql('myapp')
    #end

    # Environment Repository unit test
    #it "does return the path to the stack module when explicitly specified" do
      #stack = @env.stacks[1]
      #expect(stack.tf_module).to eql('myapp2')
    #end
  #end

  #TODO: Environment Repository feature test
  #context "Input" do
    #before(:all) do
      #stack = @env.stacks[2]
      #@input = stack.inputs.first
      #@lookup = stack.inputs[1]
    #end

    #it "does return the value for a non-local key" do
      #expect(@lookup.raw_value).to eql({'type'=>'atlas.artifact','slug'=>'unifio/aws-linux/amazon.ami','version'=>1,'key'=>'region.us-west-2'})
    #end
  #end

  #TODO: Environment Repository feature test
  #context "Context" do
    #before(:all) do
      #stack = @env.stacks[0]
      #@context = stack.contexts.first
    #end

    #it "does return the value" do
      #expect(@context.value).to eql(['module.az0'])
    #end
  #end

  #TODO: Environment Repository feature test
  #context "Input Reader" do
    #xit "does return combined configuration hash" do
      #stub_request(:any, /#{Atlas::URL}.*/).
        #to_return(:body => File.new('./spec/atlas/artifact_response.json'), :status => 200)
      #stack = @env.stacks[2]
      #inputs = InputReader.new(stack)

      #expect(inputs.to_h).to eql({'label'=>'test','ami'=>'ami-23456789'})
    #end
  #end
#end
