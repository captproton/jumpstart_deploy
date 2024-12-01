# frozen_string_literal: true

require "open3"
require "shellwords"

module JumpstartDeploy
  module ShellCommands
    class CommandError < StandardError; end
    class InvalidCommandError < CommandError; end

    # Define allowed commands with their allowed arguments
    COMMAND_WHITELIST = {
      "git" => {
        "clone" => 2,      # url, path
        "remote" => 2..3,  # add/remove, name, [url]
        "add" => 1..2,     # [options], path
        "commit" => 2,     # -m, message
        "push" => 2..3     # -u, origin, main
      },
      "bundle" => {
        "install" => 0,    # no args
        "exec" => 1..Float::INFINITY # command + args
      },
      "bin/rails" => {
        "db:create" => 0,
        "db:migrate" => 0,
        "assets:precompile" => 0
      }
    }.freeze

    def self.execute(command, subcommand, *args, dir: nil)
      validate_command!(command, subcommand, args)

      cmd_array = [ command, subcommand, *args ].compact.map(&:to_s)

      Dir.chdir(dir || Dir.pwd) do
        out, err, status = Open3.capture3(*cmd_array)
        unless status.success?
          raise CommandError, "Command failed: #{err}"
        end
        out
      end
    end

    def self.validate_command!(command, subcommand, args)
      unless COMMAND_WHITELIST.key?(command)
        raise InvalidCommandError, "Command not allowed: #{command}"
      end

      allowed_subcommands = COMMAND_WHITELIST[command]
      unless allowed_subcommands.key?(subcommand)
        raise InvalidCommandError, "Subcommand not allowed: #{subcommand} for #{command}"
      end

      allowed_args = allowed_subcommands[subcommand]
      case allowed_args
      when Integer
        unless args.length == allowed_args
          raise InvalidCommandError, "Invalid number of arguments for #{command} #{subcommand}"
        end
      when Range
        unless allowed_args.include?(args.length)
          raise InvalidCommandError, "Invalid number of arguments for #{command} #{subcommand}"
        end
      end

      validate_arguments!(args)
    end

    def self.validate_arguments!(args)
      args.each do |arg|
        if arg.to_s.match?(/[;&|]/)
          raise InvalidCommandError, "Invalid characters in argument"
        end
      end
    end

    def self.git(subcommand, *args, dir: nil)
      execute("git", subcommand, *args, dir: dir)
    end

    def self.rails(subcommand, *args, dir: nil)
      execute("bin/rails", subcommand, *args, dir: dir)
    end

    def self.bundle(subcommand, *args, dir: nil)
      execute("bundle", subcommand, *args, dir: dir)
    end
  end
end
