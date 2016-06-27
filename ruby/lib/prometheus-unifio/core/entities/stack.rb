require 'virtus'
require 'active_model'

require_relative '../../../prometheus-unifio'
require_relative 'state_store'
require_relative 'input'
require_relative 'context'

class Stack
  include Virtus.model
  include ActiveModel::Validations

  attribute :name, String
  attribute :environment_name, String
  attribute :tf_module, String
  attribute :state_stores, Array[StateStore]
  attribute :contexts, Array[Context]
  attribute :inputs, Array[Input]
  attribute :args, String

  validates! :name, format: {
    without: /\s+/,
    message: "Stack %{attribute}: \"%{value}\" cannot contain spaces"
  }

  def initialize(attributes = {}, *args)
    super
    self.valid?
  end

  def full_name
    "#{environment_name}-#{name}"
  end

  def materialize_inputs
    return_hash = {}
    inputs.each do |input|
      return_hash[input.name] = input.value
    end
    return return_hash
  end
end
