require_relative File.join(PrometheusUnifio::GEM_ROOT, 'core/entities/input')

Fabricator(:input, from: 'PrometheusUnifio::Input') do
  name "input"

  after_build(&:valid?)
end

Fabricator(:local_input, class_name: PrometheusUnifio::Input) do
  name "local_input"
  raw_value "foo"

  after_build(&:valid?)
end


Fabricator(:remote_input, class_name: PrometheusUnifio::Input) do
  name "remote_input"
  raw_value do
    {
      type: 'atlas.artifact',
      slug: 'unifio/aws-linux/amazon.ami',
      version: 1,
      key: 'region.us-west-2'
    }
  end

  after_build(&:valid?)
end
