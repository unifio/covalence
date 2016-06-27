require "prometheus-unifio/version"
require "logger"
require 'active_support/core_ext/object/blank'

if %w(development test).include?(ENV['RAKE_ENV'])
  require 'pry'
  require 'awesome_print'
end

# :reek:TooManyConstants
module PrometheusUnifio
  # Configurable constants
  WORKSPACE = File.expand_path(ENV['PROMETHEUS_WORKSPACE'] || '../../../', __FILE__)
  CONFIG = File.join(WORKSPACE, ENV['PROMETHEUS_CONFIG'] || 'prometheus.yaml')
  # TODO: could use better naming
  PACKER = File.join(WORKSPACE, ENV['PROMETHEUS_PACKER_DIR'] || 'packer')
  TERRAFORM =  File.join(WORKSPACE, ENV['PROMETHEUS_TERRAFORM_DIR'] || 'terraform')

  # should be able to deprecate this with prometheus bundled inside the container
  TF_IMG = ENV['TERRAFORM_IMG'] || ""
  TF_CMD = ENV['TERRAFORM_CMD'] || "terraform"
  TERRAFORM_VERSION = ENV['TERRAFORM_VERSION'] || `#{TF_CMD} #{TF_IMG} version`.split("\n", 2)[0].gsub('Terraform v','')

  # Internal constants
  PROJECT_ROOT = File.expand_path('../../../', __FILE__).freeze
  GEM_ROOT = File.expand_path('prometheus-unifio', File.dirname(__FILE__)).freeze
  # look into logger-colors
  LOGGER = Logger.new(STDOUT)
  # TODO: make the level configurable
  LOGGER.level = Logger::WARN
end
