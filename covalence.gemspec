# coding: utf-8
gem_root = "lib"
lib = File.expand_path(File.join("..", gem_root), __FILE__)

$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'covalence/version'
require 'covalence/helpers/spec_dependencies'

Gem::Specification.new do |spec|
  spec.name          = "covalence"
  spec.version       = Covalence::VERSION
  spec.authors       = ["Unif.io"]
  spec.email         = ["support@unif.io"]

  spec.summary       = "A tool for the management and orchestration of data used by HashiCorp infrastructure tooling."
  spec.homepage      = "https://unif.io"
  spec.license       = "MPL-2.0"

  spec.files         = Dir["*.md", "#{gem_root}/**/*"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = [ gem_root ]
  spec.required_ruby_version = '>= 2.0.0'

  spec.add_dependency "deep_merge", "~> 1.2.1"
  spec.add_dependency "hiera", "~> 3.4.3"
  spec.add_dependency "json", "~> 2.1.0"
  spec.add_dependency "rest-client", "~> 2.0.0.rc3"
  spec.add_dependency "rake", ">= 11.1.2"
  spec.add_dependency "aws-sdk-s3", "~> 1"
  spec.add_dependency "virtus", "~> 1.0.5"
  spec.add_dependency "activesupport", "~> 5.2.0"
  spec.add_dependency "activemodel", "~> 5.2.0"
  spec.add_dependency "semantic", "~> 1.6.1"
  spec.add_dependency "slop", "~> 4.6.2"
  spec.add_dependency "highline", "~> 1.7.10"
  spec.add_dependency "consul_loader", "~> 1.0.0"

  Covalence::Helpers::SpecDependencies.dependencies.each do |name, requirement|
    spec.add_development_dependency name, requirement
  end
  spec.add_development_dependency "awesome_print", "~> 1.8.0"
  spec.add_development_dependency "bundler", ">= 1.9.0"
  spec.add_development_dependency "dotenv", "~> 2.4.0"
  spec.add_development_dependency "byebug", "~> 10.0.2"
  spec.add_development_dependency "webmock", "~> 3.4.1"
  spec.add_development_dependency "fabrication", "~> 2.20.1"
  spec.add_development_dependency "simplecov", "~> 0.16.1"
  spec.add_development_dependency "solargraph"
end
