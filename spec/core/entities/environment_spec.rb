require 'spec_helper'
require_relative File.expand_path(Covalence::GEM_ROOT, 'core/entities/environment')
require_relative File.expand_path(Covalence::GEM_ROOT, 'core/entities/stack')

module Covalence
  RSpec.describe Environment do
    describe "validators" do
      it "does not allow .name with spaces" do
        expect { Fabricate(:environment, name: "bad environment") }.to raise_error(
          ActiveModel::StrictValidationFailed, /contain spaces/)
      end
    end

    describe "#stacks" do
      let(:valid_environment) { Fabricate(:environment) }

      it { expect(valid_environment.stacks).to be_kind_of(Array) }
      it "should all be instances of Stack" do
        expect(valid_environment.stacks.all? { |stack| stack.instance_of?(Stack) }).to be(true)
      end
    end
  end
end
