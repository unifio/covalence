require 'virtus'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/hash'
require 'active_model'

module PrometheusUnifio
  class Input
    include Virtus.model
    include ActiveModel::Validations

    attribute :name, String
    attribute :type, String, default: 'terraform'
    # unprocessed value, could be remote
    attribute :raw_value, Object

    validate :remote_input_type_is_valid

    def initialize(attributes = {}, *args)
      super
      self.valid?
    end

    def value
      return raw_value if value_is_local?

      backend, subcategory = parse_type()
      backend::lookup(subcategory, raw_value)
    end

    #TODO: ugh, this is horrid and error prone. Address with var-file generation
    def to_command_option
      if value.nil?
        "-var '#{name}='"
      elsif (type == 'packer')
        "-var '#{name}=#{value}'"
      elsif (Semantic::Version.new(PrometheusUnifio::TERRAFORM_VERSION) >= Semantic::Version.new("0.7.0") &&
             type == 'terraform')
        "-var '#{name}=\"#{value}\"'"
      else
        "-var #{name}=\"#{value}\""
      end
    end

    private
    def value_is_local?
      !raw_value.is_a?(Hash)
    end

    # :reek:FeatureEnvy
    def parse_type
      pieces = raw_value.stringify_keys.fetch('type').split('.', 2)
      return [ "PrometheusUnifio::#{pieces.first.camelize}".constantize,
               pieces[1] ]
    end

    def remote_input_type_is_valid
      if (!value_is_local? && !raw_value.stringify_keys.has_key?('type'))
        errors.add(:base,
                   "'type' not specified for remote value: #{Hash(raw_value)}",
        strict: true)
      end
    end
  end
end
