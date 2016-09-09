require_relative '../../../covalence'
require_relative File.join(Covalence::GEM_ROOT, 'core/services/hiera_syntax_service')

module Covalence
  RSpec.describe HieraSyntaxService do
    describe ".check_yaml" do
      let(:files) { Dir.glob("#{Covalence::WORKSPACE}/**/*.y*ml") }
      it 'passes syntax check' do
        errors = described_class.check_yaml(files)
        expect(errors).to be_empty
      end
    end
  end
end
