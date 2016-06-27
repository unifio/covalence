require 'rake'
require_relative '../prometheus-unifio'
require_relative 'helpers/spec_dependencies'

# Check gem constraints before continuing
PrometheusUnifio::Helpers::SpecDependencies.check_dependencies
require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'

class SpecTasks
  extend Rake::DSL

  def self.run
    ci_namespace_rspec_tasks
    spec_namespace_rspec_tasks
  end

  class << self
    private

    # :reek:TooManyStatements
    def ci_namespace_rspec_tasks
      desc 'Run CI tests'
      task "ci" => ['ci:setup:rspec', 'spec:envs']

      desc 'Clean spec/reports'
      task "ci:clean" => ['ci:setup:rspec']

      desc 'Verify all environments'
      task "ci:envs" => ['ci:setup:rspec', 'spec:envs']

      desc 'Check syntax of all .yaml files'
      task "ci:check_yaml" => ['ci:setup:rspec', 'spec:check_yaml']
    end

    # :reek:TooManyStatements
    # :reek:FeatureEnvy
    # :reek:UncommunicativeVariableName
    def spec_namespace_rspec_tasks
      desc "Verify environments"
      RSpec::Core::RakeTask.new("spec:envs") do |t|
        t.pattern = "#{File.join(PrometheusUnifio::GEM_ROOT, 'rake/rspec/envs_spec.rb')}"
        t.rspec_opts = '--color --format documentation'
        t.verbose = true
      end

      desc 'Check syntax of all .yaml files'
      RSpec::Core::RakeTask.new("spec:check_yaml") do |t|
        t.pattern = "#{File.join(PrometheusUnifio::GEM_ROOT, 'rake/rspec/yaml_spec.rb')}"
        t.rspec_opts = '--color --format documentation'
        t.verbose = true
      end
    end
  end
end

SpecTasks.run
