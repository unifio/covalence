require_relative File.join(PrometheusUnifio::GEM_ROOT, 'core/entities/environment')

Fabricator(:environment, from: 'PrometheusUnifio::Environment') do
  name "example_environment"
  stacks { Fabricate.times(3, :terraform_stack) }
  packer_stacks { Fabricate.times(2, :packer_stack) }

  after_build(&:valid?)
end
