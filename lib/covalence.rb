require "covalence/version"
require "logger"
require 'active_support/core_ext/object/blank'
require 'etc'

if %w(development test).include?(ENV['RAKE_ENV'])
  require 'byebug'
  require 'awesome_print'
end

# :reek:TooManyConstants
module Covalence
  # Configurable constants
  #TODO: look into how WORKSPACE is being used, maybe this can just be an internal ROOT and make CONFIG not depend on WORKSPACE
  WORKSPACE = File.absolute_path(ENV['COVALENCE_WORKSPACE'] || '.')
  CONFIG = File.join(WORKSPACE, (ENV['COVALENCE_CONFIG'] || 'covalence.yaml'))
  # TODO: could use better naming
  PACKER = File.absolute_path(File.join(WORKSPACE, (ENV['COVALENCE_PACKER_DIR'] || '.')))
  TERRAFORM =  File.absolute_path(File.join(WORKSPACE, (ENV['COVALENCE_TERRAFORM_DIR'] || '.')))
  TEST_ENVS = (ENV['COVALENCE_TEST_ENVS'] || "").split(',')
  # Reserved namespace including default ci and spec
  RESERVED_NS = [(ENV['COVALENCE_RESERVED_NAMESPACE'] || "").split(','), 'ci', 'spec', 'sops']

  TERRAFORM_CMD = ENV['TERRAFORM_CMD'] || "terraform"
  TERRAFORM_VERSION = ENV['TERRAFORM_VERSION'] || `#{TERRAFORM_CMD} version`.split("\n", 2)[0].gsub('Terraform v','')
  TERRAFORM_PLUGIN_CACHE = File.absolute_path("#{ENV['TF_PLUGIN_CACHE_DIR']}/linux_amd64" || "#{ENV['HOME']}/.terraform.d/plugin-cache/linus_amd64")

  PACKER_CMD = ENV['PACKER_CMD'] || "packer"

  SOPS_CMD = ENV['SOPS_CMD'] || "sops"
  SOPS_VERSION = ENV['SOPS_VERSION'] || (`#{SOPS_CMD} --version`.split("\n", 2)[0].gsub(/[^\d\.]/, '') rescue "0.0.0")
  SOPS_ENCRYPTED_SUFFIX = ENV['SOPS_ENCRYPTED_SUFFIX'] || "-encrypted"
  SOPS_DECRYPTED_SUFFIX = ENV['SOPS_DECRYPTED_SUFFIX'] || "-decrypted"

  # No-op shell command. Should not need to modify for most unix shells.
  DRY_RUN_CMD = (ENV['COVALENCE_DRY_RUN_CMD'] || ":")
  DEBUG_CLI = (ENV['COVALENCE_DEBUG'] || 'false') =~ (/(true|t|yes|y|1)$/i)

  #DOCKER_ENV_FILE

  # Internal constants
  GEM_ROOT = File.expand_path('covalence', File.dirname(__FILE__)).freeze
  # look into logger-colors
  LOGGER = Logger.new(STDOUT)
  LOG_LEVEL = String(ENV['COVALENCE_LOG'] || "warn").upcase
  LOGGER.level = Logger.const_get(LOG_LEVEL)

  # worker count
  WORKER_COUNT = ENV.has_key?('WORKER_COUNT') ? ENV['WORKER_COUNT'].to_i : Etc.nprocessors
end
