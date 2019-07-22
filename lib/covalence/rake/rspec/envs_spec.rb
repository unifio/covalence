require_relative '../../core/bootstrap'

module Covalence
  environments = EnvironmentRepository.find_all.select do |environ|
    TEST_ENVS.include?(environ.name.to_s)
  end

  POOL_SIZE = Covalence::WORKER_COUNT
  jobs = Queue.new
  ################ populate the job queue
  environments.each do |environment|
    environment.stacks.each do |stack|
      EnvironmentRepository.populate_stack(stack)
      jobs.push(stack)
    end
  end
  Covalence::LOGGER.info "======================> jobs.length: #{jobs.length}"

  ############### start the workers
  myworkers = (POOL_SIZE).times.map do
    Thread.new do
      begin
        while stack = jobs.pop(true)
          case stack.type
          when 'terraform'
            _tmp_dir = Dir.mktmpdir
            tf_tasks = TerraformStackTasks.new(stack)
            exit false if !tf_tasks.stack_verify(_tmp_dir)
          when 'packer'
            packer_tasks = PackerStackTasks.new(stack)
            ## exit false if !packer_tasks.context_validate(stack.contexts.first.to_packer_command_options)
          end
        end
      rescue ThreadError => e
      end
    end
  end
  myworkers.map(&:join)

=begin
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
              expect {
                expect(TerraformCli.terraform_get(path)).to be true
              }.to_not raise_error

              expect {
                expect(TerraformCli.terraform_init).to be true
              }.to_not raise_error

              stack.materialize_cmd_inputs

              tf_vers = Gem::Version.new(Covalence::TERRAFORM_VERSION)

              if tf_vers >= Gem::Version.new('0.12.0')
                # >= 0.12 does *not* support validating input vars
                expect {
                  expect(TerraformCli.terraform_validate()).to be true
                }.to_not raise_error
              else
                # < 0.12 supports validating input vars
                expect {
                  expect(TerraformCli.terraform_validate("-input=false -var-file=covalence-inputs.tfvars")).to be true
                }.to_not raise_error
              end
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
=end

end

