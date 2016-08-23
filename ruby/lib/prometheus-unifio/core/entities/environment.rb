require 'virtus'
require 'active_model'

require_relative 'stack'

module PrometheusUnifio
  class Environment
    include Virtus.model
    include ActiveModel::Validations

    attribute :name, String
    attribute :stacks, Array[Stack]

    validates! :name, format: {
      without: /\s+/,
      message: "Environment %{attribute}: \"%{value}\" cannot contain spaces"
    }

    def initialize(attributes = {}, *args)
      super
      self.valid?
    end
  end
end
