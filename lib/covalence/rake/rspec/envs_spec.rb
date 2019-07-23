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
            exit false if !packer_tasks.context_validate(stack.contexts.first.to_packer_command_options)
          end
        end
      rescue ThreadError => e
      end
    end
  end
  myworkers.map(&:join)
end

