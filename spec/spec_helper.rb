ENV['RAKE_ENV'] ||= 'test'

require 'dotenv'
require 'fabrication'
require 'webmock/rspec'
require 'simplecov'

Dotenv.load(*%w(.env .env.test))
SimpleCov.start
require_relative '../ruby/lib/prometheus-unifio'

Fabrication.manager.load_definitions
