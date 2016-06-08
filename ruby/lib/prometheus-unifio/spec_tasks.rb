require 'rake'
require_relative 'helpers/spec_dependencies'

# Check gem constraints before continuing
PrometheusUnifio::Helpers::SpecDependencies.check_dependencies

prometheus_rake_dir = File.join(File.dirname(__FILE__), 'rake')
load "#{prometheus_rake_dir}/rspec.rake"
