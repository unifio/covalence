# coding: utf-8
lib = File.expand_path('../ruby/lib', __FILE__)
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

  dirs_to_ignore = %w(bin test spec features images).join("|")
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^("#{dirs_to_ignore}")/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["ruby/lib"]

  spec.add_dependency "deep_merge", "~> 1.0.1"
  spec.add_dependency "hiera", "~> 3.2.0"
  spec.add_dependency "json", "~> 1.8.3"
  spec.add_dependency "rest-client", "~> 1.8.0"
  spec.add_dependency "rake", ">= 11.1.2"
  spec.add_dependency "aws-sdk", "~> 2.3.8"


  PrometheusUnifio::Helpers::SpecDependencies.dependencies.each do |name, requirement|
    spec.add_development_dependency name, requirement
  end
  spec.add_development_dependency "bundler", ">= 1.9.0"
  spec.add_development_dependency "dotenv", "~> 2.1.0"
  spec.add_development_dependency "pry-byebug", "~> 3.4.0"
  spec.add_development_dependency "serverspec", "~> 2.36.0"
  spec.add_development_dependency "webmock", "~> 2.0.3"
end
