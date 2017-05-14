require 'virtus'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/hash'
require 'active_model'
require 'open3'

module Covalence
  class Input
    include Virtus.model
    include ActiveModel::Validations

    attribute :name, String
    # unprocessed value, could be remote
    attribute :raw_value, Object

    def initialize(attributes = {}, *args)
      super
      self.valid?
    end

    def value
      return raw_value if !raw_value.is_a?(Hash)
      get_value(raw_value)
    end

    def to_command_option
      parsed_value = value()

      if parsed_value.nil?
        "#{name} = \"\""

      elsif parsed_value.is_a?(Hash)
        config = "#{name} = {\n"
        parsed_value.each do |k,v|
          config += "  \"#{k}\" = \"#{v}\"\n"
        end
        config += "}"

      elsif parsed_value.is_a?(Array)
        config = "#{name} = [\n"
        parsed_value.each do |v|
          config += "  \"#{v}\",\n"
        end
        config += "]"

      elsif parsed_value.start_with?("$(")
        Covalence::LOGGER.info "Evaluating interpolated value: \"#{parsed_value}\""
        interpolated_value = Open3.capture2e(ENV, "echo \"#{parsed_value}\"")[0].chomp
        "#{name} = \"#{interpolated_value}\""

      else
        "#{name} = \"#{parsed_value}\""
      end
    end

    private

    def get_value(input)
      backend, type = parse_type(input)

      if backend != "local"
        remote_value = backend::lookup(type, input)
        if remote_value.is_a?(Hash)
          get_value(remote_value)
        else
          remote_value
        end
      elsif input.stringify_keys.has_key?('value')
        input.stringify_keys.fetch('value')
      else
        input
      end
    end

    # :reek:FeatureEnvy
    def parse_type(input)
      if input.stringify_keys.has_key?('type')
        type = input.stringify_keys.fetch('type')

        local_types = %w(
          list
          map
          string
        )

        if local_types.any? {|local_type| type == local_type }
          return [ "local", type ]
        elsif type.include?('.')
          pieces = type.split('.', 2)
          return [ "Covalence::#{pieces.first.camelize}".constantize,
                   pieces[1] ]
        else
          errors.add(:base,
                     "invalid input type specified: #{type}",
                     strict: true)
        end
      else
        return [ "local", "map" ]
      end
    end

  end
end
