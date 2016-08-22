require 'virtus'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/hash'
require 'active_model'

# check to see how this works with plugins
Dir[File.expand_path('../state_stores/*.rb', File.dirname(__FILE__))].each do |file|
  require file
end

class StateStore
  include Virtus.model
  include ActiveModel::Validations

  attribute :params, Hash, :writer => :private
  attribute :backend, Object, :writer => :private

  validate :validate_params_has_name,
    :backend_has_state_store

  def initialize(attributes = {}, *args)
    super
    self.valid?
  end

  def name
    params.fetch('name')
  end

  # :reek:FeatureEnvy
  def params=(params)
    super(params.stringify_keys)
  end

  #TODO: prep different backend for plugins
  # :reek:FeatureEnvy
  def backend=(backend_name)
    super(backend_name.camelize.constantize)
  end

  def get_config
    backend::get_state_store(@params)
  end

  private
  def validate_params_has_name
    if !params.has_key?('name')
      errors.add(:base,
                 "Params #{params} missing 'name' parameter for the #{backend} state store",
                 strict: true)
    end
  end

  def backend_has_state_store
    backend_has_no_state_store = !backend.has_state_store? rescue true
    if backend_has_no_state_store
      errors.add(:base,
                 "#{backend} backend module does not support state storage",
                 strict: true)
    end
  end
end
