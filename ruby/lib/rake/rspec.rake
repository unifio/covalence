require 'rspec/core/rake_task'

if ENV['GENERATE_REPORTS'] == 'true'
  require 'ci/reporter/rake/rspec'
  task :spec => ['ci:setup:rspec', 'spec:prometheus', 'spec:environments']
  task "spec:environments" => 'ci:setup:rspec'
else
  task :spec => ['spec:prometheus', 'spec:environments']
end

ENV['TERRAFORM_STUB'] = 'true'
ENV['AWS_REGION'] = 'us-west-2'

desc 'Run all spec tests'

namespace :spec do

  desc 'Run Prometheus tests'
  RSpec::Core::RakeTask.new(:prometheus) do |t|
    t.pattern = "spec/**/*_spec.rb"
    t.rspec_opts = "--color --format documentation"
    t.verbose = true
  end

  desc 'Verify all stacks'
  RSpec::Core::RakeTask.new(:environments) do |t|
    t.pattern = "spec/environment/verify_all_tf.rb"
    t.rspec_opts = '--color --format documentation'
    t.verbose = true
  end
end
