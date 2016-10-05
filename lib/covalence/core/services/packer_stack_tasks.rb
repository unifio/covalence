require 'tempfile'
require_relative '../../../covalence'
require_relative '../cli_wrappers/packer_cli'

module Covalence
  class PackerStackTasks

    def initialize(stack)
      @template_path = File.expand_path(File.join(Covalence::PACKER, stack.packer_template))
      @stack = stack
    end

    def stack_name
      stack.name
    end

    def environment_name
      stack.environment_name
    end

    def context_build(*additional_args)
      args = collect_args(stack.materialize_cmd_inputs,
                          stack.args,
                          additional_args)
      call_packer_cmd("packer_build", args)
    end

    def context_inspect(*additional_args)
      call_packer_cmd("packer_inspect", [])
    end

    def context_validate(*additional_args)
      args = collect_args(stack.materialize_cmd_inputs,
                          stack.args,
                          additional_args)
      call_packer_cmd("packer_validate", args)
    end

    private
    attr_reader :template_path, :stack

    def call_packer_cmd(packer_cmd, args)
      begin
        tmp_file = nil
        if template_is_yaml?(template_path)
          tmp_file = Tempfile.new('file', File.dirname(template_path))
          tmp_file.write(YAML.load_file(template_path).to_json)
          tmp_file.rewind

          PackerCli.public_send(packer_cmd.to_sym, tmp_file.path, args: args)
        else
          PackerCli.public_send(packer_cmd.to_sym, template_path, args: args)
        end
      ensure
        if tmp_file
          tmp_file.close
          tmp_file.unlink
        end
      end
    end

    def template_is_yaml?(template_path)
      %w(.yaml .yml).include?(File.extname(template_path))
    end

    def collect_args(*args)
      args.flatten.compact.reject(&:empty?).map(&:strip)
    end
  end
end
