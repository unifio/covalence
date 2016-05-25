# When we're ready to release to rubygems
# require "bundler/gem_tasks"
require 'dotenv'

# Load environment variables
Dotenv.load

# all rake tasks are found in ./ruby/lib/rake
Dir.glob('ruby/lib/rake/*.rake').each { |r| import r }

task :default => :spec
