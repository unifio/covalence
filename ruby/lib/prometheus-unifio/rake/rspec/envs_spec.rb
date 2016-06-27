require_relative '../../core/bootstrap'

envs = EnvironmentRepository.all

# spec_helper
if ENV['PROMETHEUS_TEST_ENVS']
  test_envs = ENV['PROMETHEUS_TEST_ENVS'].split(',')
  envs = envs.select { |environ| test_envs.include?(environ.name.to_s) }
end

envs.each do |env|
  env.stacks.each do |stack|
    path = File.expand_path(File.join(PrometheusUnifio::TERRAFORM, stack.tf_module))

    describe "Verify #{env.name}:#{stack.name}" do

      before(:all) do
        TerraformCli.terraform_clean(path)
        TerraformCli.terraform_get(path)
      end

      it 'passes style check' do
        expect(TerraformCli.terraform_check_style(path)).to be true
      end

      it 'passes validation' do
        expect {
          TerraformCli.terraform_validate(path)
        }.to_not raise_error
      end

      it 'passes execution' do
        TerraformCli.terraform_remote_config(args: "-disable")
        args = stack.materialize_cmd_inputs + [
          "-input=false",
          "-module-depth=-1",
          stack.args.strip,
        ]
        expect(TerraformCli.terraform_plan(path, args: args)).to be true
      end
    end
  end
end
