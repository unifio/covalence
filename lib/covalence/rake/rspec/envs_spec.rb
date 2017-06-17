require_relative '../../core/bootstrap'

module Covalence
  environments = EnvironmentRepository.find_all.select do |environ|
    TEST_ENVS.include?(environ.name.to_s)
  end

  environments.each do |environment|
    environment.stacks.each do |stack|
      EnvironmentRepository.populate_stack(stack)
      case stack.type
      when 'terraform'
        tf_tasks = TerraformStackTasks.new(stack)
      when 'packer'
        packer_tasks = PackerStackTasks.new(stack)
      end

      path = File.expand_path(File.join(TERRAFORM, stack.module_path))

      describe "Verify #{environment.name}:#{stack.name}" do

        if stack.type == 'terraform'

          it 'passes style check' do
            expect {
              expect(TerraformCli.terraform_check_style(path)).to be true
            }.to_not raise_error
          end

          it 'passes validation' do
            tmp_dir = Dir.mktmpdir
            # Copy module to the workspace
            FileUtils.copy_entry path, tmp_dir

            # Copy any dependencies to the workspace
            stack.dependencies.each do |dep|
              dep_path = File.expand_path(File.join(Covalence::TERRAFORM, dep))
              FileUtils.cp_r dep_path, tmp_dir
            end

            Dir.chdir(tmp_dir) do
              TerraformCli.terraform_get(path)
              TerraformCli.terraform_init

              expect {
                expect(TerraformCli.terraform_validate).to be true
              }.to_not raise_error
            end
          end

          it 'passes execution' do
            expect {
              expect(tf_tasks.stack_verify).to be true
            }.to_not raise_error
          end

        elsif stack.type == 'packer'

          it 'passes validation' do
            expect {
              expect(packer_tasks.context_validate(stack.contexts.first.to_packer_command_options)).to be true
            }.to_not raise_error
          end
        end
      end
    end
  end
end
