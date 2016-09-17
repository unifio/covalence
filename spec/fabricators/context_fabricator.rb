require_relative File.join(Covalence::GEM_ROOT, 'core/entities/context')

Fabricator(:context, from: 'Covalence::Context') do
  name "example_context"
  values []

  after_build(&:valid?)
end
