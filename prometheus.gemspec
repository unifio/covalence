# coding: utf-8
lib = File.expand_path('../ruby/lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'prometheus-unifio/version'

Gem::Specification.new do |spec|
  spec.name          = "prometheus-unifio"
  spec.version       = Prometheus::VERSION
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

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["ruby/lib"]

  spec.add_dependency "deep_merge", "~> 1.0.1"
  spec.add_dependency "dotenv", "~> 2.1.0"
  spec.add_dependency "hiera", "~> 3.0.6"
  spec.add_dependency "json", "~> 1.8.3"
  spec.add_dependency "rest-client", "~> 1.8.0"
  spec.add_dependency "rake", ">= 10.0"
  spec.add_dependency "aws-sdk", "~> 2.2.19"

  spec.add_development_dependency "bundler", ">= 1.9.5"
  spec.add_development_dependency "ci_reporter_rspec", "~> 1.0.0"
  spec.add_development_dependency "pry-byebug", "~> 3.3.0"
  spec.add_development_dependency "rspec", "~> 3.4.0"
  spec.add_development_dependency "serverspec", "~> 2.29.2"
  spec.add_development_dependency "webmock", "~> 1.22.6"
end
