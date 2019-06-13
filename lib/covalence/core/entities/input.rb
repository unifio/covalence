require 'virtus'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/hash'
require 'active_model'

require_relative '../../helpers/shell_interpolation'

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
      "#{name} = #{parse_input(value())}"
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

    def parse_array(input)
      config = "[\n"
      input.each do |v|
        config += "  #{parse_input(v)},\n"
      end
      config += "]"
    end

    def parse_hash(input)
      config = "{\n"
      input.each do |k,v|
        config += "  \"#{k}\" = #{parse_input(v)}\n"
      end
      config += "}"
    end

    def parse_input(input)
      if input.nil?
        "\"\""

      elsif input.is_a?(Hash)
        parse_hash(input)

      elsif input.is_a?(Array)
        parse_array(input)

      elsif input.to_s.include?("$(")
        "\"#{Covalence::Helpers::ShellInterpolation.parse_shell(input)}\""

      else
        "\"#{input}\""
      end
    end

    # :reek:FeatureEnvy
    def parse_type(input)
      Covalence::LOGGER.debug("parse_type input=#{input.inspect}")

      if input.stringify_keys.has_key?('type')
        type = input.stringify_keys.fetch('type')

        # HACK This only pays attention to the first element in:
        # - map(string)     -> ["map", "string"]
        # - list(string)    -> ["list", "string"]
        # But then again, this is exactly how Terraform 0.11.x forced
        # us to handle it, so eh, yolo.
        if type.respond_to?('each')
          type = type[0]
        end

        local_types = %w(
          list
          set
          map
          string
          number
          tuple
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
