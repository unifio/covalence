require 'spec_helper'
require_relative File.join(Covalence::GEM_ROOT, 'helpers/shell_interpolation')

module Covalence
  module Helpers
    RSpec.describe ShellInterpolation do
      describe "#parse_shell" do
        let(:simple_shell_input) { "$(echo 'simple')" }
        let(:nested_shell_input) { "$(echo $((20000 + 12345 % 65535)))" }

        it "should succeed with simple_shell_input" do
          expect(Open3).to receive(:capture2e).with(anything, "echo \"#{simple_shell_input}\"").and_call_original
          expect(described_class.parse_shell(simple_shell_input)).to eq("simple")
        end


        it "should succeed with nested_shell_input" do
          expect(Open3).to receive(:capture2e).with(anything, "echo \"#{nested_shell_input}\"").and_call_original
          expect(described_class.parse_shell(nested_shell_input)).to eq("32345")
        end
      end
    end
  end
end
