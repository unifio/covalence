require 'rspec/core/rake_task'

ENV['TERRAFORM_MODE'] = "test"
ENV['AWS_REGION'] = 'us-west-2'

desc "Run all spec tests"
task :spec => "spec:prometheus"

namespace :spec do

  desc "Run Prometheus tests"
  RSpec::Core::RakeTask.new(:prometheus) do |t|
    t.pattern = "spec/**/*_spec.rb"
    t.rspec_opts = '--color --format documentation'
    t.verbose = true
  end

end
