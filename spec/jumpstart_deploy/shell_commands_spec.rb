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

RSpec.describe JumpstartDeploy::ShellCommands do
  let(:cmd) { instance_double(TTY::Command) }
  let(:result) { double(out: "command output") }

  before do
    allow(TTY::Command).to receive(:new).and_return(cmd)
    allow(cmd).to receive(:run!).and_return(result)
  end

  describe ".git" do
    # Tests focus on the standard GitHub deployment workflow
    # MVP supports both HTTPS and basic SSH URLs for GitHub only
    context "with valid deployment commands" do
      it "allows cloning a repository with HTTPS" do
        expect(cmd).to receive(:run!)
          .with("git", "clone", "https://github.com/org/repo.git", "target")
          .and_return(result)

        described_class.git("clone", "https://github.com/org/repo.git", "target")
      end

      it "allows cloning a repository with standard GitHub SSH" do
        expect(cmd).to receive(:run!)
          .with("git", "clone", "git@github.com:org/repo.git", "target")
          .and_return(result)

        described_class.git("clone", "git@github.com:org/repo.git", "target")
      end
    end

    # Security validation focuses on common attack vectors
    context "with invalid inputs" do
      it "rejects non-GitHub URLs" do
        ["http://other-git.com/repo.git", "git@other.com:repo.git"].each do |url|
          expect {
            described_class.git("clone", url, "target")
          }.to raise_error(JumpstartDeploy::ShellCommands::InvalidCommandError)
        end
      end

      it "rejects unsafe paths" do
        ["../path", "/root/path", "path/.."].each do |path|
          expect {
            described_class.git("clone", "https://github.com/org/repo.git", path)
          }.to raise_error(JumpstartDeploy::ShellCommands::InvalidCommandError)
        end
      end
    end
  end

  describe ".rails" do
    # MVP includes only essential Rails deployment commands
    it "allows essential deployment commands" do
      ["db:create", "db:migrate", "assets:precompile"].each do |cmd_name|
        expect(cmd).to receive(:run!)
          .with("bin/rails", cmd_name)
          .and_return(result)

        described_class.rails(cmd_name)
      end
    end
  end

  describe ".bundle" do
    # Bundle commands are limited to install and essential testing
    it "allows install command" do
      expect(cmd).to receive(:run!)
        .with("bundle", "install")
        .and_return(result)

      described_class.bundle("install")
    end

    context "with exec" do
      it "allows essential test commands" do
        ["rspec", "rubocop"].each do |test_cmd|
          expect(cmd).to receive(:run!)
            .with("bundle", "exec", test_cmd)
            .and_return(result)

          described_class.bundle("exec", test_cmd)
        end
      end
    end
  end

  # Error handling is essential for MVP
  describe "error handling" do
    it "raises CommandError on failure" do
      allow(cmd).to receive(:run!).and_raise(TTY::Command::ExitError.new)

      expect {
        described_class.git("clone", "https://github.com/org/repo.git", "target")
      }.to raise_error(JumpstartDeploy::ShellCommands::CommandError)
    end

    it "logs to Rails logger when available" do
      stub_const("Rails", Class.new)
      logger = double(error: true)
      allow(Rails).to receive(:logger).and_return(logger)
      allow(cmd).to receive(:run!).and_raise(TTY::Command::ExitError.new)

      expect(logger).to receive(:error)
      expect {
        described_class.git("clone", "https://github.com/org/repo.git", "target")
      }.to raise_error(JumpstartDeploy::ShellCommands::CommandError)
    end
  end
end