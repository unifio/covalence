# When we're ready to release to rubygems
# require "bundler/gem_tasks"
require 'dotenv'

# Load environment variables
Dotenv.load

require_relative 'ruby/lib/prometheus-unifio/environment_tasks'
require_relative 'ruby/lib/prometheus-unifio/spec_tasks'

task :default => :spec
