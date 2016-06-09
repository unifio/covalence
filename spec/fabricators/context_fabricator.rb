require_relative '../../ruby/lib/prometheus-unifio'
require_relative File.join(PrometheusUnifio::GEM_ROOT, 'core/entities/context')

Fabricator(:context) do
  name "example_context"
  value []

  after_build(&:valid?)
end
