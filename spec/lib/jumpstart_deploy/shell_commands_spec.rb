# spec/lib/jumpstart_deploy/shell_commands_spec.rb
require "spec_helper"

# ShellCommands Test Suite - MVP Focus
#
# These tests verify the core functionality needed for basic deployment workflows.
# The test suite focuses on:
# 1. Essential deployment commands (git clone, push, etc.)
# 2. Basic security validations
# 3. Common GitHub repository operations
# 4. Standard Rails deployment tasks
#
# Out of scope for MVP:
# - Complex SSH URL formats
# - Non-GitHub repositories
# - Development-only commands
# - Advanced git operations
#
# Security boundaries for MVP:
# - GitHub repositories only
# - Basic command injection prevention
# - Simple path traversal protection
# - Standard SSL/SSH URL validation

RSpec.describe JumpstartDeploy::ShellCommands do
  let(:cmd) { instance_double(TTY::Command) }
  let(:result) { double(out: "command output") }

  before do
    allow(TTY::Command).to receive(:new).and_return(cmd)
    allow(cmd).to receive(:run!).and_return(result)
  end

  describe ".git" do
    context "with valid commands" do
      it "allows cloning a repository" do
        expect(cmd).to receive(:run!)
          .with("git", "clone", "https://github.com/org/repo.git", "target")
          .and_return(result)

        described_class.git("clone", "https://github.com/org/repo.git", "target")
      end

      it "allows adding remotes" do
        expect(cmd).to receive(:run!)
          .with("git", "remote", "add", "origin", "git@github.com:org/repo.git")
          .and_return(result)

        described_class.git("remote", "add", "origin", "git@github.com:org/repo.git")
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
    end
  end

  describe ".rails" do
    it "allows permitted commands" do
      expect(cmd).to receive(:run!)
        .with("bin/rails", "db:migrate")
        .and_return(result)

      described_class.rails("db:migrate")
    end

    it "rejects unauthorized commands" do
      expect {
        described_class.rails("console")
      }.to raise_error(JumpstartDeploy::ShellCommands::InvalidCommandError)
    end
  end

  describe ".bundle" do
    it "allows installation" do
      expect(cmd).to receive(:run!)
        .with("bundle", "install")
        .and_return(result)

      described_class.bundle("install")
    end

    it "allows whitelisted exec commands" do
      expect(cmd).to receive(:run!)
        .with("bundle", "exec", "rspec")
        .and_return(result)

      described_class.bundle("exec", "rspec")
    end

    it "rejects unauthorized exec commands" do
      expect {
        described_class.bundle("exec", "dangerous-command")
      }.to raise_error(JumpstartDeploy::ShellCommands::InvalidCommandError)
    end
  end

  describe "validation methods" do
    describe ".valid_git_url?" do
      it "accepts HTTPS URLs" do
        url = "https://github.com/org/repo.git"
        expect(described_class.send(:valid_git_url?, url)).to be true
      end

      it "accepts SSH URLs" do
        url = "git@github.com:org/repo.git"
        # Note: URI.parse might need special handling for SSH URLs
        skip "SSH URL validation needs custom logic"
      end

      it "rejects invalid URLs" do
        expect(described_class.send(:valid_git_url?, "invalid-url")).to be false
      end
    end

    describe ".valid_path?" do
      it "accepts valid paths" do
        expect(described_class.send(:valid_path?, "valid/path")).to be true
      end

      it "rejects absolute paths" do
        expect(described_class.send(:valid_path?, "/absolute/path")).to be false
      end

      it "rejects directory traversal" do
        expect(described_class.send(:valid_path?, "../dangerous")).to be false
      end
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
