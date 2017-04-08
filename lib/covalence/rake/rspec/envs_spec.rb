require_relative '../../core/bootstrap'

module Covalence
  envs = EnvironmentRepository.all.select do |environ|
    TEST_ENVS.include?(environ.name.to_s)
  end

  envs.each do |env|
    env.stacks.each do |stack|
      path = File.expand_path(File.join(TERRAFORM, stack.tf_module))

      describe "Verify #{env.name}:#{stack.name}" do

        before(:all) do
          TerraformCli.terraform_clean(path)
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
          TerraformCli.terraform_get(path)

          args = stack.materialize_cmd_inputs + [
            "-input=false",
            stack.args.strip,
          ]
          expect(TerraformCli.terraform_plan(path, args: args)).to be true
        end
      end
    end
  end
end
