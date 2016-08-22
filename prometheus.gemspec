# coding: utf-8
gem_root = "ruby/lib"
lib = File.expand_path(File.join("..", gem_root), __FILE__)

$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'prometheus-unifio/version'
require 'prometheus-unifio/helpers/spec_dependencies'

Gem::Specification.new do |spec|
  spec.name          = "prometheus-unifio"
  spec.version       = PrometheusUnifio::VERSION
  spec.authors       = ["Unif.io"]
  spec.email         = ["support@unif.io"]

  spec.summary       = "Ruby orchestration framework for HashiCorp based deployment pipelines."
  #spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "http://unif.io"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = Dir["*.md", "#{gem_root}/**/*"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = [ gem_root ]

  spec.add_dependency "deep_merge", "~> 1.0.1"
  spec.add_dependency "hiera", "~> 3.2.0"
  spec.add_dependency "json", "~> 1.8.3"
  spec.add_dependency "rest-client", "~> 2.0.0.rc3"
  spec.add_dependency "rake", ">= 11.1.2"
  spec.add_dependency "aws-sdk", "~> 2.3.8"
  spec.add_dependency "virtus", "~> 1.0.5"
  spec.add_dependency "activesupport", "~> 4.2.6"
  spec.add_dependency "activemodel", "~> 4.2.6"
  spec.add_dependency "semantic", "~> 1.4.1"

  PrometheusUnifio::Helpers::SpecDependencies.dependencies.each do |name, requirement|
    spec.add_development_dependency name, requirement
  end
  spec.add_development_dependency "awesome_print", "~> 1.7.0"
  spec.add_development_dependency "bundler", ">= 1.9.0"
  spec.add_development_dependency "dotenv", "~> 2.1.0"
  spec.add_development_dependency "pry-byebug", "~> 3.4.0"
  spec.add_development_dependency "serverspec", "~> 2.36.0"
  spec.add_development_dependency "webmock", "~> 2.0.3"
  spec.add_development_dependency "gemfury", "~> 0.6.0"
  spec.add_development_dependency "fabrication", "~> 2.15.2"
  spec.add_development_dependency "simplecov", "~> 0.12.0"
end
