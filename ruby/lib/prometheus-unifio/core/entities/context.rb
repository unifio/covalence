require 'virtus'
require 'active_model'

# Maybe just call this targets
class Context
  include Virtus.model
  include ActiveModel::Validations

  attribute :name, String, default: ''
  attribute :value, Array, default: []

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
end
