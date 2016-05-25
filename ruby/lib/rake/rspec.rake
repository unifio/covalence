require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'
require_relative '../tools/hiera.rb'
require_relative '../prometheus'
require_relative '../environment'

env_rdr = EnvironmentReader.new

task :ci => ['ci:setup:rspec', 'spec:all']
task :spec => 'spec:prometheus'

desc 'Run all spec tests'

namespace :spec do

  desc 'Run Prometheus tests'
  RSpec::Core::RakeTask.new(:prometheus) do |t|
    t.pattern = "spec/**/*_spec.rb"
    t.rspec_opts = "--color --format documentation"
    t.verbose = true
  end

  desc "Verify all environments"
  RSpec::Core::RakeTask.new(:all) do |t|
    t.pattern = 'ci/spec/*_spec.rb'
    t.rspec_opts = '--color --format documentation'
    t.verbose = true
  end

  desc 'Check syntax of all .yaml files'
  RSpec::Core::RakeTask.new(:yaml) do |t|
    t.pattern = 'ci/spec/yaml_spec.rb'
    t.rspec_opts = '--color --format documentation'
    t.verbose = true
  end

  env_rdr.environments.each do |environ|

    desc "Run verification tests for the #{environ.to_s} environment"
    RSpec::Core::RakeTask.new(environ.to_sym) do |t|
      t.pattern = "ci/spec/#{environ.to_s}_spec.rb"
      t.rspec_opts = '--color --format documentation'
      t.verbose = true
    end
  end
end

namespace :ci do

  desc 'Check syntax of all .yaml files'
  task :check_yaml => ['ci:setup:rspec', 'spec:yaml']

  desc 'Verify all environments'
  task :all => ['ci:setup:rspec', 'spec:all']

  env_rdr.environments.each do |environ|

    desc "Run CI tests for the #{environ.to_s} environment"
    task environ.to_sym => ['ci:setup:rspec', "spec:#{environ.to_s}"]
  end
end
