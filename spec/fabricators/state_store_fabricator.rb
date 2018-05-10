require_relative File.join(Covalence::GEM_ROOT, 'core/entities/state_store')

Fabricator(:state_store, from: 'Covalence::StateStore') do
  on_init do
    init_with(
      params: { name: "example/state_store" },
      backend: "s3",
      workspace_enabled: false
    )
  end

  after_build(&:valid?)
end
