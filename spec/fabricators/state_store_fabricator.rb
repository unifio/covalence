require_relative File.join(PrometheusUnifio::GEM_ROOT, 'core/entities/state_store')

Fabricator(:state_store) do
  on_init do
    init_with(
      params: { name: "example/state_store" },
      backend: "s3"
    )
  end

  after_build(&:valid?)
end
