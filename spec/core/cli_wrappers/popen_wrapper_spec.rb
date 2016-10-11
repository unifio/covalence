require 'spec_helper'
require 'tempfile'
require_relative File.join(Covalence::GEM_ROOT, 'core/cli_wrappers/popen_wrapper')

module Covalence
  RSpec.describe PopenWrapper do
    describe ".run" do
      before(:all) do
        @stdin_io_file = Tempfile.new
        @stdout_io =
        @stderr_io = Tempfile.new
      end

      before(:each) do
        allow(Covalence::LOGGER).to receive(:warn)
      end

      after(:all) do
        @stdin_io_file.close
        @stdin_io_file.unlink
      end

      let(:stdin_io) do
        fd = IO.sysopen('/dev/null', 'r+')
        IO.new(fd)
      end
      let(:stdout_io) do
        fd = IO.sysopen('/dev/null', 'w+')
        IO.new(fd)
      end
      let(:stderr_io) do
        fd = IO.sysopen('/dev/null', 'w+')
        IO.new(fd)
      end

      let(:cmds) { "echo" }
      let(:args) { "\'args\'" }

      it "traps SIGINT"

      it "exits with the the process error code with a non-successful exit" do
        begin
          described_class.run("exit 1", '', '',
                              stdin_io: stdin_io,
                              stdout_io: stdout_io,
                              stderr_io: stderr_io)
          expect('should not reach here').to eq(true)
        rescue SystemExit => e
          expect(e.status).to eq(1)
        end
      end

      it "returns 0 when process terminates successfully" do
        result = described_class.run(cmds, '', args,
                                     stdin_io: stdin_io,
                                     stdout_io: stdout_io,
                                     stderr_io: stderr_io)
        expect(result).to eq(0)
      end

      it "sends the command string to the logger" do
        expect(Covalence::LOGGER).to receive(:warn)
        result = described_class.run(cmds, '', args,
                                     stdin_io: stdin_io,
                                     stdout_io: stdout_io,
                                     stderr_io: stderr_io)

        expect(result).to eq(0)
      end

      context "debug: true" do
        it "prompts before execution and aborts with exit code 0 when declined to continue" do
          expect_any_instance_of(HighLine).to receive(:agree).and_return(false)
          expect(described_class).to_not receive(:spawn_subprocess)

          result = described_class.run(cmds, '', args,
                                     stdin_io: stdin_io,
                                     stdout_io: stdout_io,
                                     stderr_io: stderr_io,
                                     debug: true)

          expect(result).to eq(0)
        end

        it "prompts before execution and returns with exit code 0 when accepted to continue" do
          expect_any_instance_of(HighLine).to receive(:agree).and_return(true)
          expect(described_class).to receive(:spawn_subprocess).and_call_original

          result = described_class.run(cmds, '', args,
                                     stdin_io: stdin_io,
                                     stdout_io: stdout_io,
                                     stderr_io: stderr_io,
                                     debug: true)

          expect(result).to eq(0)
        end
      end

      context "dry_run: true" do
        it "replaces the run_cmd string with DRY_RUN_CMD" do
          expect(described_class).to receive(:spawn_subprocess).with(anything,
                                                                     Covalence::DRY_RUN_CMD,
                                                                     anything).and_call_original
          result = described_class.run(cmds, '', args,
                                       stdin_io: stdin_io,
                                       stdout_io: stdout_io,
                                       stderr_io: stderr_io,
                                       dry_run: true)
          expect(result).to eq(0)
        end
      end

      context "ignore_exitcode: true" do
        it "should return 0 when ignoring the exitcode" do
          result = nil
          expect {
            result = described_class.run("exit 1", '', '',
                                stdin_io: stdin_io,
                                stdout_io: stdout_io,
                                stderr_io: stderr_io,
                                ignore_exitcode: true)
          }.to_not raise_error
          expect(result).to eq(0)
        end
      end
    end
  end
end
