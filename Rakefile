# When we're ready to release to rubygems
# require "bundler/gem_tasks"

# all rake tasks are found in ./ruby/lib/rake
Dir.glob('ruby/lib/rake/*.rake').each { |r| import r }

ENV['PROMETHEUS_CONFIG'] = "spec/prometheus_spec.yaml"
ENV['PROMETHEUS_TERRAFORM_DIR'] = "spec/environment"
ENV['PROMETHEUS_PACKER_DIR'] = "spec/environment"

task :default => :spec
