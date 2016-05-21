require_relative '../../ruby/lib/environment.rb'
require_relative '../../ruby/lib/tools/terraform.rb'

test_env = 'example'
env_rdr = EnvironmentReader.new
envs = env_rdr.environments

envs.each do |env|
  next unless env.to_s == test_env
  env.stacks.each do |stack|

    describe "Verify #{env}:#{stack}" do

      before(:all) do
        @tf = Terraform::Stack.new(stack.tf_module, stub: false)
        @inputs = InputReader.new(stack)
        @tf.clean
        @tf.get
      end

      it 'passes style check' do
        expect {
          @tf.check_style
        }.to_not raise_error
      end

      it 'passes validation' do
        expect {
          @tf.validate
        }.to_not raise_error
      end

      it 'passes execution' do
        input_args = @tf.parse_vars(@inputs.to_h)
        expect {
          @tf.plan("#{input_args} -input=false -module-depth=-1 #{stack.args}".strip)
        }.to_not raise_error
      end
    end
  end
end
