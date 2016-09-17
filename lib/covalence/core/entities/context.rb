require 'active_support/core_ext/object/blank'
require 'virtus'
require 'active_model'

module Covalence
  # Maybe just call this targets
  class Context
    include Virtus.model
    include ActiveModel::Validations

    attribute :name, String, default: ''
    attribute :values, Array, default: []

    validates! :name, format: {
      without: /(\s+|,)/,
      message: "Context %{attribute}: \"%{value}\" cannot contain spaces or commas"
    }

    def initialize(attributes = {}, *args)
      super
      self.valid?
    end

    def namespace
      return "" if name.blank?
      "#{name}:"
    end

    def to_command_options
      values.map { |value| "-target=\"#{value}\"" }
    end

    def to_packer_command_options
      return "" if values.blank?
      "-only=#{values.join(',')}"
    end
  end
end
