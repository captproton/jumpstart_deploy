# spec/lib/jumpstart_deploy/shell_commands_spec.rb
require "spec_helper"

# ShellCommands Test Suite - MVP Focus
#
# These tests verify essential GitHub deployment workflow functionality.
# The test suite focuses on:
# 1. Core deployment commands (git clone, remote, commit, push)
# 2. Basic security validations
# 3. Error handling
#
# Out of scope for MVP:
# - Complex URL validation
# - Non-GitHub workflows
# - Development commands
# - Advanced git operations

RSpec.describe JumpstartDeploy::ShellCommands do
  let(:cmd) { instance_double(TTY::Command) }
  let(:result) { double(out: "command output") }

  before do
    allow(TTY::Command).to receive(:new).and_return(cmd)
    allow(cmd).to receive(:run!).and_return(result)
  end

  describe ".git" do
    context "deployment workflow" do
      it "clones repository" do
        expect(cmd).to receive(:run!)
          .with("git", "clone", "https://github.com/org/repo.git", "target")
          .and_return(result)

        described_class.git("clone", "https://github.com/org/repo.git", "target")
      end

      it "configures remote" do
        expect(cmd).to receive(:run!)
          .with("git", "remote", "add", "origin", "git@github.com:org/repo.git")
          .and_return(result)

        described_class.git("remote", "add", "origin", "git@github.com:org/repo.git")
      end

      it "commits changes" do 
        expect(cmd).to receive(:run!)
          .with("git", "commit", "-m", "Initial commit")
          .and_return(result)

        described_class.git("commit", "-m", "Initial commit")
      end

      it "pushes to remote" do
        expect(cmd).to receive(:run!)
          .with("git", "push", "-u", "origin", "main")
          .and_return(result)

        described_class.git("push", "-u", "origin", "main") 
      end

      it "removes remote" do
        expect(cmd).to receive(:run!)
          .with("git", "remote", "remove", "origin")
          .and_return(result)

        described_class.git("remote", "remove", "origin")
      end
    end

    context "with invalid commands" do
      it "rejects invalid URLs" do
        expect {
          described_class.git("clone", "invalid-url", "target")
        }.to raise_error(JumpstartDeploy::ShellCommands::InvalidCommandError)
      end

      it "rejects dangerous paths" do
        expect {
          described_class.git("clone", "https://github.com/org/repo.git", "../dangerous")
        }.to raise_error(JumpstartDeploy::ShellCommands::InvalidCommandError)
      end

      it "rejects dangerous commit messages" do
        expect {
          described_class.git("commit", "-m", "message; rm -rf /")
        }.to raise_error(JumpstartDeploy::ShellCommands::InvalidCommandError) 
      end
    end
  end

  describe ".rails" do
    context "deployment commands" do
      it "runs database migrations" do
        expect(cmd).to receive(:run!)
          .with("bin/rails", "db:migrate")
          .and_return(result)

        described_class.rails("db:migrate")
      end

      it "creates database" do
        expect(cmd).to receive(:run!)
          .with("bin/rails", "db:create")
          .and_return(result)

        described_class.rails("db:create")
      end

      it "precompiles assets" do
        expect(cmd).to receive(:run!)
          .with("bin/rails", "assets:precompile")
          .and_return(result)

        described_class.rails("assets:precompile")
      end
    end

    it "rejects unauthorized commands" do
      expect {
        described_class.rails("console")
      }.to raise_error(JumpstartDeploy::ShellCommands::InvalidCommandError)
    end
  end

  describe ".bundle" do
    it "installs dependencies" do
      expect(cmd).to receive(:run!)
        .with("bundle", "install")
        .and_return(result)

      described_class.bundle("install")
    end

    it "rejects unauthorized exec commands" do
      expect {
        described_class.bundle("exec", "dangerous-command")
      }.to raise_error(JumpstartDeploy::ShellCommands::InvalidCommandError)
    end
  end

  describe "error handling" do
    it "handles command failures" do
      allow(cmd).to receive(:run!).and_raise(TTY::Command::ExitError.new)

      expect {
        described_class.git("clone", "https://github.com/org/repo.git", "target")
      }.to raise_error(JumpstartDeploy::ShellCommands::CommandError)
    end

    context "with Rails logger" do
      before do
        stub_const("Rails", Class.new)
        allow(Rails).to receive(:logger).and_return(double(error: true))
      end

      it "logs errors when Rails is defined" do
        allow(cmd).to receive(:run!).and_raise(TTY::Command::ExitError.new)
        expect(Rails.logger).to receive(:error)

        expect {
          described_class.git("clone", "https://github.com/org/repo.git", "target")
        }.to raise_error(JumpstartDeploy::ShellCommands::CommandError)
      end
    end
  end
end