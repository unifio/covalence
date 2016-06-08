require_relative '../core/bootstrap'

env_rdr = EnvironmentReader.new

desc "Clean all environments"
task "all:clean" do
  env_rdr.environments.each do |environ|
    Rake::Task["#{environ}:clean"].execute
  end
end

desc "Verify all environments"
task "all:verify" do
  env_rdr.environments.each do |environ|
    Rake::Task["#{environ}:verify"].execute
  end
end

env_rdr.environments.each do |environ|
  namespace environ.to_sym do
    environ.stacks.each do |stack|

      tf = Terraform::Stack.new(stack.tf_module)
      inputs = InputReader.new(stack)

      # Pull primary state store
      store_args = stack.state_stores.first.get_config

      # Stack tasks
      namespace stack.to_sym do

        desc "Clean the #{stack.to_s} stack of the #{environ.to_s} environment"
        task :clean do
          tf.clean
        end

        desc "Format the #{stack.to_s} stack of the #{environ.to_s} environment"
        task :format do
          tf.fmt
        end

        desc "Verify the #{stack.to_s} stack of the #{environ.to_s} environment"
        task :verify do
          input_args = tf.parse_vars(inputs.to_h)
          tf.clean
          tf.get
          tf.validate
          tf.plan("#{input_args} -input=false -module-depth=-1 #{stack.args}".strip)
        end

        stack.contexts.each do |context|

          target_args = tf.parse_targets(context.value)

          desc "Create execution plan for the #{stack.to_s} stack of the #{environ.to_s} environment"
          task "#{context.namespace}plan".strip do
            input_args = tf.parse_vars(inputs.to_h)
            tf.clean
            tf.remote_config(store_args)
            tf.get
            tf.plan("#{input_args} -input=false -module-depth=-1 #{stack.args} #{target_args}".strip)
          end

          desc "Create destruction plan for the #{stack.to_s} stack of the #{environ.to_s} environment"
          task "#{context.namespace}plan_destroy" do
            input_args = tf.parse_vars(inputs.to_h)
            tf.clean
            tf.get
            tf.plan("#{input_args} -destroy -input=false -module-depth=-1 #{stack.args} #{target_args}".strip)
          end

          desc "Apply changes to the #{stack.to_s} stack of the #{environ.to_s} environment"
          task "#{context.namespace}apply" do
            input_args = tf.parse_vars(inputs.to_h)
            tf.clean
            tf.remote_config(store_args)
            tf.get
            tf.plan("#{input_args} -input=false -module-depth=-1 #{stack.args} #{target_args}".strip)
            tf.apply("#{input_args} #{stack.args} #{target_args}".strip)
          end

          desc "Apply changes to the #{stack.to_s} stack of the #{environ.to_s} environment"
          task "#{context.namespace}destroy" do
            input_args = tf.parse_vars(inputs.to_h)
            tf.clean
            tf.remote_config(store_args)
            tf.get
            tf.plan("#{input_args} -destroy -input=false -module-depth=-1 #{stack.args} #{target_args}".strip)
            tf.destroy("#{input_args} #{stack.args} #{target_args}".strip)
          end
        end

        desc "Synchronize state stores for the #{stack.to_s} stack of the #{environ.to_s} environment"
        task :sync do
          input_args = tf.parse_vars(inputs.to_h)
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
    desc "Clean the #{environ} environment"
    task :clean do
      environ.stacks.each do |stack|
        Rake::Task["#{environ}:#{stack.name}:clean"].execute
      end
    end

    desc "Verify the #{environ} environment"
    task :verify do
      environ.stacks.each do |stack|
        Rake::Task["#{environ}:#{stack.name}:verify"].execute
      end
    end

    desc "Create execution plan for the #{environ} environment"
    task :plan do
      environ.stacks.each do |stack|
        stack.contexts.each do |context|
          Rake::Task["#{environ}:#{stack.name}:#{context.namespace}plan"].execute
        end
      end
    end

    desc "Create destruction plan for the #{environ} environment"
    task :plan_destroy do
      environ.stacks.each do |stack|
        stack.contexts.each do |context|
          Rake::Task["#{environ}:#{stack.name}:#{context.namespace}plan_destroy"].execute
        end
      end
    end

    desc "Apply changes to the #{environ} environment"
    task :apply do
      environ.stacks.each do |stack|
        stack.contexts.each do |context|
          Rake::Task["#{environ}:#{stack.name}:#{context.namespace}apply"].execute
        end
      end
    end

    desc "Destroy the #{environ} environment"
    task :destroy do
      environ.stacks.reverse.each do |stack|
        stack.contexts.each do |context|
          Rake::Task["#{environ}:#{stack.name}:#{context.namespace}destroy"].execute
        end
      end
    end

    desc "Synchronize state stores for the #{environ} environment"
    task :sync do
      environ.stacks.each do |stack|
        Rake::Task["#{environ}:#{stack.name}:sync"].execute
      end
    end
  end
end
