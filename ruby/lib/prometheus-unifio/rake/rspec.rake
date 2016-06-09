require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'

require_relative '../../prometheus-unifio'

task :ci => ['ci:setup:rspec', 'spec:envs']
task :spec => 'spec:prometheus'

desc 'Run all spec tests'

namespace :spec do

  # extract into spec helper.
  desc 'Run Prometheus tests'
  RSpec::Core::RakeTask.new(:prometheus) do |t|
    t.pattern = "#{File.join(PrometheusUnifio::PROJECT_ROOT, 'spec/**/*_spec.rb')}"
    t.rspec_opts = "--color --format documentation"
    t.verbose = true
  end

  desc "Verify environments"
  RSpec::Core::RakeTask.new(:envs) do |t|
    t.pattern = "#{File.join(PrometheusUnifio::GEM_ROOT, 'rake/rspec/envs_spec.rb')}"
    t.rspec_opts = '--color --format documentation'
    t.verbose = true
  end

  desc 'Check syntax of all .yaml files'
  RSpec::Core::RakeTask.new(:check_yaml) do |t|
    t.pattern = "#{File.join(PrometheusUnifio::GEM_ROOT, 'rake/rspec/yaml_spec.rb')}"
    t.rspec_opts = '--color --format documentation'
    t.verbose = true
  end

end

namespace :ci do
  desc 'Clean spec/reports'
  task :clean => ['ci:setup:rspec']

  # extract into spec helper.
  desc 'Run Prometheus tests'
  task :prometheus => ['ci:setup:rspec', 'spec:prometheus']

  desc 'Verify all environments'
  task :envs => ['ci:setup:rspec', 'spec:envs']

  desc 'Check syntax of all .yaml files'
  task :check_yaml => ['ci:setup:rspec', 'spec:check_yaml']

end
