require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'
require_relative '../prometheus'
require_relative '../environment'

ENV['GENERATE_REPORTS'] == 'true'

env_rdr = EnvironmentReader.new

desc "Verify all environments"
RSpec::Core::RakeTask.new('ci:all') do |t|
  env_rdr.environments.each do |environ|
    Rake::Task["ci:#{environ.to_s}"].execute
  end
end

env_rdr.environments.each do |environ|

  desc "Run CI tests for the #{environ.to_s} environment"
  task "ci:#{environ.to_s}" => ['ci:setup:rspec', "spec:#{environ.to_s}"]

  RSpec::Core::RakeTask.new("spec:#{environ.to_s}") do |t|
    t.pattern = "#{Prometheus::RSPEC}/environment/#{environ.to_s}_spec.rb"
    t.rspec_opts = '--color --format documentation'
    t.verbose = true
  end
end
