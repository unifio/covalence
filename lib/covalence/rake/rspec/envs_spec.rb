require_relative '../../core/bootstrap'

module Covalence
  envs = EnvironmentRepository.all.select do |environ|
    TEST_ENVS.include?(environ.name.to_s)
  end

  envs.each do |env|
    env.stacks.each do |stack|
      path = File.expand_path(File.join(TERRAFORM, stack.module_path))

      describe "Verify #{env.name}:#{stack.name}" do

        before(:each) do
          @tmp_dir = Dir.mktmpdir
          # Copy module to the workspace
          FileUtils.copy_entry path, @tmp_dir

          # Copy any dependencies to the workspace
          stack.dependencies.each do |dep|
            Covalence::LOGGER.info "Copying '#{dep}' dependency to #{@tmp_dir}"
            dep_path = File.expand_path(File.join(Covalence::TERRAFORM, dep))
            FileUtils.cp_r dep_path, @tmp_dir
          end
        end

        after(:each) do
          FileUtils.remove_entry @tmp_dir
        end

        if stack.type == 'terraform'

          it 'passes style check' do
            expect {
              expect(TerraformCli.terraform_check_style(path)).to be true
            }.to_not raise_error
          end

          it 'passes validation' do
            Dir.chdir(@tmp_dir) do
              Covalence::LOGGER.info "In #{@tmp_dir}:"

              TerraformCli.terraform_get(path)
              TerraformCli.terraform_init

              expect {
                expect(TerraformCli.terraform_validate).to be true
              }.to_not raise_error
            end
          end

          it 'passes execution' do
            Dir.chdir(@tmp_dir) do
              Covalence::LOGGER.info "In #{@tmp_dir}:"

              TerraformCli.terraform_get(path)
              TerraformCli.terraform_init

              stack.materialize_cmd_inputs
              args = ["-input=false", stack.args, "-var-file=covalence-inputs.tfvars"].flatten.compact.reject(&:empty?).map(&:strip)

              expect {
                expect(TerraformCli.terraform_plan(args: args)).to be true
              }.to_not raise_error
            end
          end

        elsif stack.type == 'packer'

          it 'passes validation' do
            pending
          end

          it 'passes execution' do
            pending
          end
        end

      end
    end
  end

end
