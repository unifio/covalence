require 'rake'
require 'consul_loader'
require_relative '../covalence'

module Covalence
  class ConsulTasks
    extend Rake::DSL

    def self.run
      desc 'Load K/V data into Consul service'
      task 'consul_load' do
        load_yaml("#{ENV['CONSUL_KV_FILE']}")
      end
    end

    class << self
      private
      def load_yaml(filename)
        consul_loader = ConsulLoader::Loader.new(ConsulLoader::ConfigParser.new)
        consul_server = "http://#{ENV['CONSUL_HTTP_ADDR']}"
        consul_loader.load_config(filename, consul_server)
      end
    end
  end
end

Covalence::ConsulTasks.run
