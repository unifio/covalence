require 'virtus'
require 'active_model'

# Maybe just call this targets
class Context
  include Virtus.model
  include ActiveModel::Validations

  attribute :name, String, default: ''
  attribute :values, Array, default: []

  validates! :name, format: {
    without: /\s+/,
    message: "Context %{attribute}: \"%{value}\" cannot contain spaces"
  }

  def initialize(attributes = {}, *args)
    super
    self.valid?
  end

  def namespace
    name.empty? ? '' : "#{name}:"
  end

  def to_command_options
    values.map { |value| "-target=\"#{value}\"" }
  end
end
