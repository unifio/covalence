require "prometheus-unifio/version"
require 'pry'

module PrometheusUnifio
  # Configurable constants
  WORKSPACE = File.expand_path(ENV['PROMETHEUS_WORKSPACE'] || '../../../', __FILE__)
  CONFIG = File.join(WORKSPACE, ENV['PROMETHEUS_CONFIG'] || 'prometheus.yaml')
  PACKER = File.join(WORKSPACE, ENV['PROMETHEUS_PACKER_DIR'] || 'packer')
  TERRAFORM =  File.join(WORKSPACE, ENV['PROMETHEUS_TERRAFORM_DIR'] || 'terraform')

  # Internal constants
  PROJECT_ROOT = File.expand_path('../../../', __FILE__).freeze
  GEM_ROOT = File.expand_path('prometheus-unifio', File.dirname(__FILE__)).freeze
end
