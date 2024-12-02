require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe JumpstartDeploy::ShellCommands do
  let(:cmd) { TTY::Command.new(printer: :null) }

  before do
    allow(TTY::Command).to receive(:new).and_return(cmd)
  end

  describe '.execute' do
    context 'with allowed commands' do
      it 'executes git clone successfully' do
        expect(cmd).to receive(:run!)
          .with('git', 'clone', 'https://github.com/example/repo.git', 'local-path')
          .and_return(double(out: 'success'))

        result = described_class.execute(
          'git',
          'clone',
          'https://github.com/example/repo.git',
          'local-path'
        )
        expect(result).to eq('success')
      end

      it 'executes bundle install successfully' do
        expect(cmd).to receive(:run!)
          .with('bundle', 'install')
          .and_return(double(out: 'success'))

        result = described_class.execute('bundle', 'install')
        expect(result).to eq('success')
      end
    end

    context 'with disallowed commands' do
      it 'raises InvalidCommandError for unknown commands' do
        expect {
          described_class.execute('unknown', 'command')
        }.to raise_error(JumpstartDeploy::ShellCommands::InvalidCommandError, /Command not allowed/)
      end

      it 'raises InvalidCommandError for unknown subcommands' do
        expect {
          described_class.execute('git', 'invalid')
        }.to raise_error(JumpstartDeploy::ShellCommands::InvalidCommandError, /Subcommand not allowed/)
      end
    end

    context 'with invalid arguments' do
      it 'validates git URLs' do
        expect {
          described_class.execute('git', 'clone', 'invalid-url', 'path')
        }.to raise_error(JumpstartDeploy::ShellCommands::InvalidCommandError)
      end

      it 'validates paths' do
        expect {
          described_class.execute('git', 'clone', 'https://github.com/example/repo.git', '../invalid/path')
        }.to raise_error(JumpstartDeploy::ShellCommands::InvalidCommandError)
      end
    end

    context 'with directory handling' do
      let(:test_dir) { File.join(Dir.tmpdir, "test_#{Time.now.to_i}") }

      before do
        FileUtils.mkdir_p(test_dir)
      end

      after do
        FileUtils.rm_rf(test_dir)
      end

      it 'executes commands in specified directory' do
        expect(cmd).to receive(:run!)
          .with('bundle', 'install')
          .and_return(double(out: 'success'))

        described_class.execute('bundle', 'install', dir: test_dir)
      end
    end
  end

  describe '.git' do
    it 'executes git commands' do
      expect(cmd).to receive(:run!)
        .with('git', 'clone', 'https://github.com/example/repo.git', 'path')
        .and_return(double(out: 'success'))

      described_class.git('clone', 'https://github.com/example/repo.git', 'path')
    end

    it 'validates remote names' do
      expect {
        described_class.git('push', 'invalid;remote', 'main')
      }.to raise_error(JumpstartDeploy::ShellCommands::InvalidCommandError)
    end

    it 'validates commit messages' do
      expect {
        described_class.git('commit', '-m', 'message; rm -rf /')
      }.to raise_error(JumpstartDeploy::ShellCommands::InvalidCommandError)
    end
  end

  describe '.bundle' do
    it 'executes bundle commands' do
      expect(cmd).to receive(:run!)
        .with('bundle', 'install')
        .and_return(double(out: 'success'))

      described_class.bundle('install')
    end

    it 'validates bundle exec commands' do
      expect {
        described_class.bundle('exec', 'dangerous-command')
      }.to raise_error(JumpstartDeploy::ShellCommands::InvalidCommandError)
    end
  end

  describe '.rails' do
    it 'executes rails commands' do
      expect(cmd).to receive(:run!)
        .with('bin/rails', 'db:migrate')
        .and_return(double(out: 'success'))

      described_class.rails('db:migrate')
    end

    it 'rejects unauthorized rails commands' do
      expect {
        described_class.rails('console')
      }.to raise_error(JumpstartDeploy::ShellCommands::InvalidCommandError)
    end
  end
end
