# lib/jumpstart_deploy/shell_commands.rb
# frozen_string_literal: true

require "open3"
require "shellwords"

module JumpstartDeploy
  module ShellCommands
    class CommandError < StandardError; end
    class InvalidCommandError < CommandError; end

    ALLOWED_COMMANDS = ["git", "bundle", "bin/rails"].freeze

    def self.execute(*cmd, dir: nil)
      cmd = Array(cmd).flatten.compact
      return false if cmd.empty?

      # Validate the base command
      base_command = cmd.first.to_s
      unless ALLOWED_COMMANDS.include?(base_command)
        raise InvalidCommandError, "Command not allowed: #{base_command}"
      end

      # Sanitize all arguments
      safe_cmd = cmd.map { |arg| Shellwords.escape(arg.to_s) }

      Dir.chdir(dir || Dir.pwd) do
        stdout, stderr, status = Open3.capture3(*safe_cmd)
        unless status.success?
          raise CommandError, "Command failed: #{stderr}"
        end
        stdout
      end
    end

    def self.git(*args, dir: nil)
      args = args.map(&:to_s)
      # Only allow specific git commands
      allowed_git_commands = %w[clone remote add remove commit push]
      command = args.first
      unless allowed_git_commands.include?(command)
        raise InvalidCommandError, "Git command not allowed: #{command}"
      end

      execute("git", *args, dir: dir)
    end

    def self.rails(*args, dir: nil)
      args = args.map(&:to_s)
      # Only allow specific rails commands
      allowed_rails_commands = %w[db:create db:migrate assets:precompile]
      command = args.first
      unless allowed_rails_commands.include?(command)
        raise InvalidCommandError, "Rails command not allowed: #{command}"
      end

      execute("bin/rails", *args, dir: dir)
    end

    def self.bundle(*args, dir: nil)
      args = args.map(&:to_s)
      # Only allow specific bundle commands
      allowed_bundle_commands = %w[install exec]
      command = args.first
      unless allowed_bundle_commands.include?(command)
        raise InvalidCommandError, "Bundle command not allowed: #{command}"
      end

      execute("bundle", *args, dir: dir)
    end
  end
end
