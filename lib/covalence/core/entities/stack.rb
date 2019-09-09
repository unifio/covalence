require 'virtus'
require 'active_model'
require 'semantic'

require_relative '../../../covalence'
require_relative 'state_store'
require_relative 'input'
require_relative 'context'

module Covalence
  class Stack
    include Virtus.model
    include ActiveModel::Validations

    attribute :type, String
    attribute :name, String
    attribute :environment_name, String
    attribute :module_path, String
    attribute :dependencies, Array[String]
    attribute :packer_template, String
    attribute :state_stores, Array[StateStore]
    attribute :contexts, Array[Context]
    attribute :inputs, Hash[String => Input]
    attribute :args, String
    attribute :workspace, String

    validates! :type, inclusion: {
      in: %w(terraform packer)
    }
    validates! :name, format: {
      without: /\s+/,
      message: "Stack %{attribute}: \"%{value}\" cannot contain spaces"
    }

    def initialize(attributes = {}, *arguments)
      super
      self.valid?
    end

    def full_name
      "#{environment_name}-#{name}"
    end

    def materialize_cmd_inputs(path)
      if type == "terraform"
        config = ""
        inputs.values.map(&:to_command_option).each do |input|
          config += input + "\n"
        end
        logger.info "#{module_path} \nStack inputs:\n\n#{config}"
        File.open("#{path}/covalence-inputs.tfvars",'w') {|f| f.write(config)}
      elsif type == "packer"
        config = Hash.new
        inputs.each do |name, input|
          config[name] = input.value
        end
        config_json = JSON.generate(config)
        logger.info "path: #{path} module_path: #{module_path}\nStack inputs:\n\n#{config_json}"
        File.open("#{path}/covalence-inputs.json",'w') {|f| f.write(config_json)}
      end
    end

    def materialize_state_inputs(store: state_stores.first, path: '.')
      config = store.get_config
      logger.info "\nState store configuration:\n\n#{config}"
      File.open("#{path}/covalence-state.tf",'w') {|f| f.write(config)}
    end

    def logger
      Covalence::LOGGER
    end

  end
end
