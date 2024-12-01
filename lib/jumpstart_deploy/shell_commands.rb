# frozen_string_literal: true

require "open3"

module JumpstartDeploy
  module ShellCommands
    class CommandError < StandardError; end

    def self.execute(*cmd, dir: nil)
      cmd = Array(cmd).flatten.compact
      return false if cmd.empty?

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
