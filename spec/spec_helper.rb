ENV['RAKE_ENV'] ||= 'test'

require 'dotenv'
require 'fabrication'

Dotenv.load
Fabrication.manager.load_definitions

require_relative '../ruby/lib/prometheus-unifio'
