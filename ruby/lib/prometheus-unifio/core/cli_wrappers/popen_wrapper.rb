# A WIP, this will eventually wrap Open3#popen3 to provide better cli control
#
#require 'open3'
require_relative '../../../prometheus-unifio'

module PrometheusUnifio
  class PopenWrapper
    def self.run(cmds, path, args)
      # TODO: terraform cmd env switch
      #cmd = "terraform #{[*cmds].join(' ')}"

      # TODO: implement path prefix for the docker runs, see @tf_cmd
      cmd_string = [*cmds]
      cmd_string += [*args] unless args.blank?
      cmd_string << path unless path.blank?

      #TODO debug command string maybe
      #TODO debug command args maybe

      # TODO: read through http://ruby-doc.org/stdlib-2.0.0/libdoc/tmpdir/rdoc/Dir.html to see how to make this optionally persist
      #stdout, stderr, status = Open3.capture3(ENV, "terraform", *cmd_string, chdir: tmp_dir)
      # TODO: cmd escape issues with -var.
      #stdout, stderr, status = Open3.capture3(ENV, cmd_string.join(' '), chdir: path)
      #if status != 0
      #raise RuntimeError, "Command failed with status (#{status}): \n#{stderr}\n#{stdout}"
      #else
      #puts stdout
      #stdout.strip
      #end

      run_cmd = cmd_string.join(' ')
      PrometheusUnifio::LOGGER.warn "---"
      PrometheusUnifio::LOGGER.warn run_cmd

      Kernel.system(ENV.to_h, run_cmd)
    end
  end
end
