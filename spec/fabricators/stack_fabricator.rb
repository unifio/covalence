require_relative File.join(PrometheusUnifio::GEM_ROOT, 'core/entities/stack')

Fabricator(:stack) do
  on_init { init_with(name: "example_stack") }
  environment_name "example_environment"
  state_stores { Fabricate.times(3, :state_store) }
  inputs { [Fabricate(:local_input), Fabricate(:remote_input)] }
  contexts { Fabricate.times(2, :context) }
  args "-no-color"

  after_build(&:valid?)
end
