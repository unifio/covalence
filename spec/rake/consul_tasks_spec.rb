require 'spec_helper'

require_relative File.join(Covalence::GEM_ROOT, 'consul_tasks')
require_relative '../shared_contexts/rake.rb'

module Covalence
  describe ConsulTasks do
    let(:task_files) { 'consul_tasks.rb' }

    # TODO: this test can use better bite
    describe "consul_load" do
      include_context "rake"

      it "cleans the workspace" do
        expect_any_instance_of(ConsulLoader::Loader).to receive(:load_config).with("spec/fixtures/data/consul-kv.yml", "http://")
        subject.invoke
      end
    end
  end
end
