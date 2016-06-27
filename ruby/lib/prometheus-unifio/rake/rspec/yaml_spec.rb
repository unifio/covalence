require_relative '../../../prometheus-unifio'
require_relative File.join(PrometheusUnifio::GEM_ROOT, 'core/services/hiera_syntax_service')

RSpec.describe HieraSyntaxService do
  describe ".check_yaml" do
    let(:files) { Dir.glob("#{PrometheusUnifio::WORKSPACE}/**/*.yaml") }
    it 'passes syntax check' do
      errors = described_class.check_yaml(files)
      expect(errors).to be_empty
    end
  end
end
