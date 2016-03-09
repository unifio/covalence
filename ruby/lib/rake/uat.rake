require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'
require_relative '../prometheus'

ENV['GENERATE_REPORTS'] == 'true'

desc 'Run all CI tests'
task :ci => ['ci:setup:rspec', 'ci:all:verify']

namespace :ci do

  desc 'Verify all stacks'
  RSpec::Core::RakeTask.new('all:verify') do |t|
    t.pattern = "#{Prometheus::RSPEC}/environment/verify_all_spec.rb"
    t.rspec_opts = '--color --format documentation'
    t.verbose = true
  end
end
