require 'rake'
require_relative '../prometheus'

module Terraform
  STACKS_DIR = Prometheus::TERRAFORM
  TF_STUB = ENV['TERRAFORM_STUB'] || ""
  TF_ENV = ENV['TERRAFORM_ENV'] || ""
  TF_CMD = ENV['TERRAFORM_CMD'] || "terraform"

  class Stack
    def initialize(name, dir: STACKS_DIR, env: TF_ENV, cmd: TF_CMD, stub: TF_STUB)
      self.path = File.join(dir, name)
      @env = env
      @cmd = cmd
      @stub = !!(stub =~ /^(true|t|yes|y|1)$/i)
    end

    def path=(path)
      raise "#{path} doesn't exist" unless Dir.exists?(path)
      @path = path
    end

    def remote_config(args='')
      run_cmd('remote', "config #{args}")
    end

    def remote_pull()
      run_cmd('remote','pull')
    end

    def remote_push()
      run_cmd('remote','push')
    end

    def get(args='')
      run_cmd('get', args)
    end

    def plan(args='')
      run_cmd('plan', args)
    end

    def apply(args='')
      run_cmd('apply', args)
    end

    def destroy(args='')
      run_cmd('destroy', args)
    end

    def clean()
      Dir.chdir(@path) do
        Rake.sh "rm -fr .terraform *.tfstate*" unless @stub
      end
    end

    def parse_vars(vars)
      vars.map { |var, value| "-var #{var}=#{value}" }.join(' ')
    end

    def parse_targets(targets)
      targets.map { |target| "-target=#{target}" }.join(' ')
    end

    def run_cmd(cmd, args)
      Dir.chdir(@path) do
        run_rake_cmd cmd, args
      end
    end

    def run_rake_cmd(cmd, args='')
      Rake.sh "#{@env} #{@cmd} #{cmd} #{args}".strip unless @stub
    end
  end
end
