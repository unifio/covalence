# all rake tasks are found in ./ruby/lib/rake
Dir.glob('ruby/lib/rake/*.rake').each { |r| import r }

ENV['PROMETHEUS_CONFIG'] = "spec/prometheus_spec.yml"
ENV['PROMETHEUS_TERRAFORM_DIR'] = "spec/environment"
ENV['PROMETHEUS_PACKER_DIR'] = "spec/environment"

task :default => :spec
