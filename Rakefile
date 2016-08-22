# When we're ready to release to rubygems
# require "bundler/gem_tasks"
require 'dotenv'
require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'

Dotenv.load

require_relative 'ruby/lib/prometheus-unifio'
#require_relative File.join(PrometheusUnifio::GEM_ROOT, 'environment_tasks')
#require_relative File.join(PrometheusUnifio::GEM_ROOT, 'spec_tasks')

namespace :spec do
  # TODO: Might be able to just use the default rspec spec?
  desc 'Run Prometheus tests'
  RSpec::Core::RakeTask.new(:prometheus) do |t|
    t.pattern = "#{File.join(PrometheusUnifio::PROJECT_ROOT, 'spec/**/*_spec.rb')}"
    t.rspec_opts = "--color --format documentation"
    t.verbose = true
  end

  desc 'Run CircleCI friendly Prometheus tests'
  RSpec::Core::RakeTask.new(:circleci) do |t|
    t.pattern = "#{File.join(PrometheusUnifio::PROJECT_ROOT, 'spec/**/*_spec.rb')}"
    t.rspec_opts = "--color --format documentation --tag ~native"
    t.verbose = true
  end
end

desc 'Run all spec tests'
task :spec => 'spec:prometheus'

desc 'Run Prometheus tests'
task "ci:prometheus" => ['ci:setup:rspec', 'spec:circleci']

task :default => :spec
