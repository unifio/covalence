require 'yaml'

require_relative '../../prometheus-unifio'

# TODO: Slowly building up to eventually just turn this to auto require everything under core
require_relative 'data_stores/hiera'

Dir[File.expand_path("entities/**/*.rb", File.dirname(__FILE__))].sort.each { |file| require file }
Dir[File.expand_path("repositories/**/*.rb", File.dirname(__FILE__))].sort.each { |file| require file }

require_relative 'services/hiera_syntax_service'

Dir[File.expand_path('../../tools/*.rb', File.dirname(__FILE__))].each do |file|
  require file
end
