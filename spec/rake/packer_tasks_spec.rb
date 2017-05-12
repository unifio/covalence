require 'spec_helper'
require 'active_support/core_ext/kernel/reporting'

require_relative File.join(Covalence::GEM_ROOT, 'core/cli_wrappers/packer_cli')
require_relative File.join(Covalence::GEM_ROOT, 'core/cli_wrappers/popen_wrapper')
require_relative File.join(Covalence::GEM_ROOT, 'packer_tasks')
require_relative '../shared_contexts/rake.rb'

module Covalence
  describe PackerTasks do
    let(:task_files) { 'packer_tasks.rb' }

    before(:each) do
      allow(PopenWrapper).to receive(:run).and_return(true)
      # suppress FileUtils verbose
      allow($stderr).to receive(:write)
      ARGV.clear
    end

    describe "example:packer_test:packer-inspect" do
      include_context "rake"

      it "converts a YML build template to JSON" do
        buffer = StringIO.new()
        filename = 'covalence-packer-template.json'
        content = "{\"variables\":{\"aws_access_key\":\"\",\"aws_secret_key\":\"\"},\"builders\":[{\"type\":\"amazon-ebs\",\"access_key\":\"{{user `aws_access_key`}}\",\"secret_key\":\"{{user `aws_secret_key`}}\",\"region\":\"us-east-1\",\"source_ami\":\"ami-fce3c696\",\"instance_type\":\"t2.micro\",\"ssh_username\":\"ubuntu\",\"ami_name\":\"packer-example {{timestamp}}\"}]}"

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "inspects the build template" do
        expect(PackerCli).to receive(:packer_inspect)
        subject.invoke
      end
    end

    describe "example:packer_test:packer-validate" do
      include_context "rake"

      it "converts a YML build template to JSON" do
        buffer = StringIO.new()
        filename = 'covalence-packer-template.json'
        content = "{\"variables\":{\"aws_access_key\":\"\",\"aws_secret_key\":\"\"},\"builders\":[{\"type\":\"amazon-ebs\",\"access_key\":\"{{user `aws_access_key`}}\",\"secret_key\":\"{{user `aws_secret_key`}}\",\"region\":\"us-east-1\",\"source_ami\":\"ami-fce3c696\",\"instance_type\":\"t2.micro\",\"ssh_username\":\"ubuntu\",\"ami_name\":\"packer-example {{timestamp}}\"}]}"

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "generates an inputs varfile" do
        buffer = StringIO.new()
        filename = 'covalence-inputs.json'
        content = "{\"aws_access_key\":\"testing\",\"aws_secret_key\":\"testing\"}"

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "validates the build template" do
        expect(PackerCli).to receive(:packer_validate)
        subject.invoke
      end
    end

    describe "example:packer_test:packer-build" do
      include_context "rake"

      it "converts a YML build template to JSON" do
        buffer = StringIO.new()
        filename = 'covalence-packer-template.json'
        content = "{\"variables\":{\"aws_access_key\":\"\",\"aws_secret_key\":\"\"},\"builders\":[{\"type\":\"amazon-ebs\",\"access_key\":\"{{user `aws_access_key`}}\",\"secret_key\":\"{{user `aws_secret_key`}}\",\"region\":\"us-east-1\",\"source_ami\":\"ami-fce3c696\",\"instance_type\":\"t2.micro\",\"ssh_username\":\"ubuntu\",\"ami_name\":\"packer-example {{timestamp}}\"}]}"

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "generates an inputs varfile" do
        buffer = StringIO.new()
        filename = 'covalence-inputs.json'
        content = "{\"aws_access_key\":\"testing\",\"aws_secret_key\":\"testing\"}"

        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(filename,'w').and_yield(buffer)
        subject.invoke
        expect(buffer.string).to eq(content)
      end

      it "executes the build" do
        expect(PackerCli).to receive(:packer_build)
        subject.invoke
      end
    end
  end
end
