# frozen_string_literal: true

require "open3"

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

      Dir.chdir(dir || Dir.pwd) do
        stdout, stderr, status = Open3.capture3(*cmd)
        unless status.success?
          raise CommandError, "Command failed: #{stderr}"
        end
        stdout
      end
    end

    def self.git(*args, dir: nil)
      execute("git", *args, dir: dir)
    end

    def self.rails(*args, dir: nil)
      execute("bin/rails", *args, dir: dir)
    end

    def self.bundle(*args, dir: nil)
      execute("bundle", *args, dir: dir)
    end
  end
end