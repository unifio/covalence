require 'open3'

module Covalence
  module Helpers
    class ShellInterpolation

      def self.parse_shell(input)
        Covalence::LOGGER.info "Evaluating requested interpolation: \"#{input}\""
        matches = input.scan(/.?\$\([^)]*\)/)

        Covalence::LOGGER.debug "matches: #{matches}"
        matches.each do |cmd|
          if cmd[0] != "\\"
            cmd = cmd[1..-1] unless cmd[0] == "$"
            interpolated_value = Open3.capture2e(ENV, "echo \"#{cmd}\"")[0].chomp
            input = input.gsub(cmd, interpolated_value)
            Covalence::LOGGER.debug "updated value: #{input}"
          else
            input = input.gsub(cmd, cmd[1..-1])
          end
        end
        Covalence::LOGGER.info "Interpolated value: \"#{input}\""
        return input
      end

    end
  end
end
