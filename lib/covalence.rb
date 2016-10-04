require "covalence/version"
require "logger"
require 'active_support/core_ext/object/blank'

if %w(development test).include?(ENV['RAKE_ENV'])
  require 'byebug'
  require 'awesome_print'
end

# :reek:TooManyConstants
module Covalence
  # Configurable constants
  #TODO: look into how WORKSPACE is being used, maybe this can just be an internal ROOT and make CONFIG not depend on WORKSPACE
  WORKSPACE = File.absolute_path((ENV['COVALENCE_WORKSPACE'] || ENV['PROMETHEUS_WORKSPACE'] || '.'))
  CONFIG = File.join(WORKSPACE, (ENV['COVALENCE_CONFIG'] || ENV['PROMETHEUS_CONFIG'] || 'covalence.yaml'))
  # TODO: could use better naming
  PACKER = File.absolute_path(File.join(WORKSPACE, (ENV['COVALENCE_PACKER_DIR'] || ENV['PROMETHEUS_PACKER_DIR'] || 'packer')))
  TERRAFORM =  File.absolute_path(File.join(WORKSPACE, (ENV['COVALENCE_TERRAFORM_DIR'] || ENV['PROMETHEUS_TERRAFORM_DIR'] || 'terraform')))
  PACKER_CMD = ENV['PACKER_CMD'] || "packer"
  TEST_ENVS = (ENV['COVALENCE_TEST_ENVS'] || ENV['PROMETHEUS_TEST_ENVS'] || "").split(',')

  # should be able to deprecate this with covalence bundled inside the container
  TF_IMG = ENV['TERRAFORM_IMG'] || ""
  TF_CMD = ENV['TERRAFORM_CMD'] || "terraform"
  TERRAFORM_VERSION = ENV['TERRAFORM_VERSION'] || `#{TF_CMD} #{TF_IMG} version`.split("\n", 2)[0].gsub('Terraform v','')

  # Internal constants
  GEM_ROOT = File.expand_path('covalence', File.dirname(__FILE__)).freeze
  # look into logger-colors
  LOGGER = Logger.new(STDOUT)
  # TODO: make the level configurable
  LOGGER.level = Logger::WARN
end
