require 'tempfile'
require 'active_support/core_ext/string/strip'

require 'spec_helper'
require_relative File.join(PrometheusUnifio::GEM_ROOT, 'core/services/hiera_syntax_service')

module PrometheusUnifio
  RSpec.describe HieraSyntaxService do
    describe ".check_yaml" do
      let(:invalid_yaml_contents) do
        <<-DOC.strip_heredoc
        ---
        :invalid
          :yaml: test
        DOC
      end

      let(:valid_yaml_contents) do
        <<-DOC.strip_heredoc
        ---
        this_is: a_test
        DOC
      end

      it "should find no errors on a valid yaml file" do
        Tempfile.open('valid') do |f|
          f.write(valid_yaml_contents)
          f.rewind

          errors = described_class.check_yaml(f.path)
          expect(errors).to be_empty
        end
      end

      it "should find errors on an invalid yaml file" do
        Tempfile.open('invalid') do |f|
          f.write(invalid_yaml_contents)
          f.rewind

          errors = described_class.check_yaml(f.path)
          expect(errors).to_not be_empty
        end
      end
    end
  end
end
