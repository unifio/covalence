require_relative File.join(PrometheusUnifio::GEM_ROOT, 'core/entities/stack')

Fabricator(:stack, from: 'PrometheusUnifio::Stack') do
  on_init { init_with(name: "example_stack") }
  environment_name "example_environment"
  state_stores { Fabricate.times(3, :state_store) }
  inputs do
    {
      'local_input' => Fabricate(:local_input),
      'remote_input' => Fabricate(:remote_input)
    }
  end
  contexts { Fabricate.times(2, :context) }
  args "-no-color"
  #tf_module
  #packer_template
  #state_stores
  #inputs

  after_build(&:valid?)
end

Fabricator(:terraform_stack, from: :stack) do
  on_init do
    init_with(name: "example_stack",
              type: "terraform")
  end
end


Fabricator(:packer_stack, from: :stack) do
  on_init do
    init_with(name: "example_stack",
              type: "packer")
  end
end
