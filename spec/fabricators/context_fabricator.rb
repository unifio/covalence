require_relative File.join(PrometheusUnifio::GEM_ROOT, 'core/entities/context')

Fabricator(:context) do
  name "example_context"
  values []

  after_build(&:valid?)
end
