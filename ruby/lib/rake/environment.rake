require_relative '../environment'
require_relative '../tools/atlas'
require_relative '../tools/terraform'

env_rdr = EnvironmentReader.new

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

      # Process input parameters
      input_args = tf.parse_vars(stack.vars)

      # Pull primary state store
      store_args = stack.state_stores.first.config

      # Stack tasks
      namespace stack.to_sym do

        desc "Verify the #{stack.to_s} stack of the #{environ.to_s} environment"
        task :verify do
          tf.clean()
          tf.get()
          tf.plan(input_args)
        end

        desc "Create execution plan for the #{stack.to_s} stack of the #{environ.to_s} environment"
        task :plan do
          tf.clean()
          tf.remote_config(store_args)
          tf.get()
          tf.plan("#{input_args} -input=false -module-depth=-1")
        end

        desc "Create destruction plan for the #{stack.to_s} stack of the #{environ.to_s} environment"
        task :plan_destroy do
          tf.clean()
          tf.get()
          tf.plan("#{input_args} -destroy -input=false -module-depth=-1")
        end

        desc "Apply changes to the #{stack.to_s} stack of the #{environ.to_s} environment"
        task :apply do
          tf.clean()
          tf.remote_config(store_args)
          tf.get()
          tf.plan("#{input_args} -input=false -module-depth=-1")
          tf.apply(input_args)
        end

        desc "Apply changes to the #{stack.to_s} stack of the #{environ.to_s} environment"
        task :destroy do
          tf.clean()
          tf.remote_config(store_args)
          tf.get()
          tf.plan("#{input_args} -destroy -input=false -module-depth=-1")
          tf.destroy(input_args)
        end

        desc "Synchronize state stores for the #{stack.to_s} stack of the #{environ.to_s} environment"
        task :sync do
          tf.clean()
          tf.remote_config(store_args)

          stack.state_stores.drop(1).each do |store|
            tf.remote_config('-disable')
            tf.remote_config("#{store.config} -pull=false")
            tf.remote_push()
          end
        end
      end
    end

    # Environment tasks
    desc "Verify the #{environ} environment"
    task :verify do
      environ.stacks.each do |stack|
        Rake::Task["#{environ}:#{stack.name}:verify"].execute
      end
    end

    desc "Create execution plan for the #{environ} environment"
    task :plan do
      environ.stacks.each do |stack|
        Rake::Task["#{environ}:#{stack.name}:plan"].execute
      end
    end

    desc "Create destruction plan for the #{environ} environment"
    task :plan_destroy do
      environ.stacks.each do |stack|
        Rake::Task["#{environ}:#{stack.name}:plan_destroy"].execute
      end
    end

    desc "Apply change to the #{environ} environment"
    task :apply do
      environ.stacks.each do |stack|
        Rake::Task["#{environ}:#{stack.name}:apply"].execute
      end
    end

    desc "Destroy the #{environ} environment"
    task :destroy do
      environ.stacks.each do |stack|
        Rake::Task["#{environ}:#{stack.name}:destroy"].execute
      end
    end
  end
end
