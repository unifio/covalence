require_relative File.join(Covalence::GEM_ROOT, 'core/entities/stack')

Fabricator(:stack, from: 'Covalence::Stack') do
  on_init { init_with(name: "example_stack") }
  environment_name "example_environment"
  inputs do
    {
      'local_input' => Fabricate(:local_input),
      'remote_input' => Fabricate(:remote_input)
    }
  end
  contexts { Fabricate.times(2, :context) }
  args "-no-color"
  #state_stores - terraform only
  #tf_module - terraform only
  #packer_template - packer only
  #state_stores - terraform only

  after_build(&:valid?)
end

Fabricator(:terraform_stack, from: :stack) do
  on_init do
    init_with(name: "example_stack",
              type: "terraform",
              state_stores: Fabricate.times(3, :state_store))
  end
end


Fabricator(:packer_stack, from: :stack) do
  on_init do
    init_with(name: "example_stack",
              type: "packer",
              packer_template: 'example_packer_template')
  end
end
