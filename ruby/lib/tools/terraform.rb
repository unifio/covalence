require 'rake'
require_relative '../prometheus'

module Terraform
  STACKS_DIR = Prometheus::TERRAFORM
  TF_STUB = ENV['TERRAFORM_STUB'] || ""
  TF_ENV = ENV['TERRAFORM_ENV'] || ""
  TF_IMG = ENV['TERRAFORM_IMG'] || ""
  TF_CMD = ENV['TERRAFORM_CMD'] || "terraform"

  class Stack
    def initialize(name, dir: STACKS_DIR, env: TF_ENV, img: TF_IMG, cmd: TF_CMD, stub: TF_STUB)
      self.path = File.join(dir, name)
      @env = env
      @stub = !!(stub =~ /^(true|t|yes|y|1)$/i)

      if img.empty?
        @tf_cmd = cmd
        @cln_cmd = "/bin/sh -c"
      else
        @tf_cmd = "#{cmd} -v #{dir}:/data -w /data/#{name} #{img}"
        @cln_cmd = "#{cmd} -v #{dir}:/data -w /data/#{name} --entrypoint=\"/bin/sh\" #{img} -c"
      end
    end

    def path=(path)
      raise "#{path} doesn't exist" unless Dir.exists?(path)
      @path = path
    end

    def remote_config(args='')
      run_cmd('remote', "config #{args}".strip)
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

    def validate(args='')
      run_cmd('validate', args)
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

    def fmt(args='')
      run_cmd('fmt', args)
    end

    def clean()
      Dir.chdir(@path) do
        Rake.sh "#{@cln_cmd} \"rm -fr .terraform *.tfstate*\"" unless @stub
      end
    end

    def parse_vars(vars)
      vars.map { |var, value| "-var #{var}=\"#{value}\"" }.join(' ')
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
      Rake.sh "#{@env} #{@tf_cmd} #{cmd} #{args}".strip unless @stub
    end
  end

  # Return module capabilities
  def self.has_key_read?
    return false
  end

  def self.has_key_write?
    return false
  end

  def self.has_state_read?
    return false
  end

  def self.has_state_store?
    return false
  end

end
