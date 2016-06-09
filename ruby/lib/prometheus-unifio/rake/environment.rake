require_relative '../core/bootstrap'

desc "Clean all environments"
task "all:clean" do
  EnvironmentRepository.all.each do |environ|
    Rake::Task["#{environ.name}:clean"].execute
  end
end

desc "Verify all environments"
task "all:verify" do
  EnvironmentRepository.all.each do |environ|
    Rake::Task["#{environ.name}:verify"].execute
  end
end

EnvironmentRepository.all.each do |environ|
  namespace environ.name do
    environ.stacks.each do |stack|

      tf = Terraform::Stack.new(stack.tf_module)

      # Pull primary state store
      store_args = stack.state_stores.first.get_config

      # Stack tasks
      namespace stack.name do

        desc "Clean the #{stack.name} stack of the #{environ.name} environment"
        task :clean do
          tf.clean
        end

        desc "Format the #{stack.name} stack of the #{environ.name} environment"
        task :format do
          tf.fmt
        end

        desc "Verify the #{stack.name} stack of the #{environ.name} environment"
        task :verify do
          input_args = tf.parse_vars(stack.materialize_inputs)
          tf.clean
          tf.get
          tf.validate
          tf.plan("#{input_args} -input=false -module-depth=-1 #{stack.args}".strip)
        end

        stack.contexts.each do |context|

          target_args = tf.parse_targets(context.value)

          desc "Create execution plan for the #{stack.name} stack of the #{environ.name} environment"
          task "#{context.namespace}plan".strip do
            input_args = tf.parse_vars(stack.materialize_inputs)
            tf.clean
            tf.remote_config(store_args)
            tf.get
            tf.plan("#{input_args} -input=false -module-depth=-1 #{stack.args} #{target_args}".strip)
          end

          desc "Create destruction plan for the #{stack.name} stack of the #{environ.name} environment"
          task "#{context.namespace}plan_destroy" do
            input_args = tf.parse_vars(stack.materialize_inputs)
            tf.clean
            tf.get
            tf.plan("#{input_args} -destroy -input=false -module-depth=-1 #{stack.args} #{target_args}".strip)
          end

          desc "Apply changes to the #{stack.name} stack of the #{environ.name} environment"
          task "#{context.namespace}apply" do
            input_args = tf.parse_vars(stack.materialize_inputs)
            tf.clean
            tf.remote_config(store_args)
            tf.get
            tf.plan("#{input_args} -input=false -module-depth=-1 #{stack.args} #{target_args}".strip)
            tf.apply("#{input_args} #{stack.args} #{target_args}".strip)
          end

          desc "Apply changes to the #{stack.name} stack of the #{environ.name} environment"
          task "#{context.namespace}destroy" do
            input_args = tf.parse_vars(stack.materialize_inputs)
            tf.clean
            tf.remote_config(store_args)
            tf.get
            tf.plan("#{input_args} -destroy -input=false -module-depth=-1 #{stack.args} #{target_args}".strip)
            tf.destroy("#{input_args} #{stack.args} #{target_args}".strip)
          end
        end

        desc "Synchronize state stores for the #{stack.name} stack of the #{environ.name} environment"
        task :sync do
          input_args = tf.parse_vars(stack.materialize_inputs)
          tf.clean
          tf.remote_config(store_args)

          stack.state_stores.drop(1).each do |store|
            tf.remote_config('-disable')
            tf.remote_config("#{store.get_config} -pull=false")
            tf.remote_push
          end
        end
      end
    end

    # Environment tasks
    desc "Clean the #{environ.name} environment"
    task :clean do
      environ.stacks.each do |stack|
        Rake::Task["#{environ.name}:#{stack.name}:clean"].execute
      end
    end

    desc "Verify the #{environ.name} environment"
    task :verify do
      environ.stacks.each do |stack|
        Rake::Task["#{environ.name}:#{stack.name}:verify"].execute
      end
    end

    desc "Create execution plan for the #{environ.name} environment"
    task :plan do
      environ.stacks.each do |stack|
        stack.contexts.each do |context|
          Rake::Task["#{environ.name}:#{stack.name}:#{context.namespace}plan"].execute
        end
      end
    end

    desc "Create destruction plan for the #{environ.name} environment"
    task :plan_destroy do
      environ.stacks.each do |stack|
        stack.contexts.each do |context|
          Rake::Task["#{environ.name}:#{stack.name}:#{context.namespace}plan_destroy"].execute
        end
      end
    end

    desc "Apply changes to the #{environ.name} environment"
    task :apply do
      environ.stacks.each do |stack|
        stack.contexts.each do |context|
          Rake::Task["#{environ.name}:#{stack.name}:#{context.namespace}apply"].execute
        end
      end
    end

    desc "Destroy the #{environ.name} environment"
    task :destroy do
      environ.stacks.reverse.each do |stack|
        stack.contexts.each do |context|
          Rake::Task["#{environ.name}:#{stack.name}:#{context.namespace}destroy"].execute
        end
      end
    end

    desc "Synchronize state stores for the #{environ.name} environment"
    task :sync do
      environ.stacks.each do |stack|
        Rake::Task["#{environ.name}:#{stack.name}:sync"].execute
      end
    end
  end
end
