require_relative '../../core/bootstrap'

test_env = 'example'
envs = EnvironmentRepository.all

# spec_helper
if ENV['PROMETHEUS_TEST_ENVS']
  test_envs = ENV['PROMETHEUS_TEST_ENVS'].split(',')
  envs = envs.select { |environ| test_envs.include?(environ.to_s) }
end

envs.each do |env|
  env.stacks.each do |stack|

    describe "Verify #{env.name}:#{stack.name}" do

      before(:all) do
        @tf = Terraform::Stack.new(stack.tf_module, stub: false)
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
        input_args = @tf.parse_vars(stack.materialize_inputs)
        expect {
          @tf.plan("#{input_args} -input=false -module-depth=-1 #{stack.args}".strip)
        }.to_not raise_error
      end
    end
  end
end
