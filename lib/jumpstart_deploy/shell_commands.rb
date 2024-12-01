# frozen_string_literal: true

module JumpstartDeploy
  module ShellCommands
    class CommandError < StandardError; end
    class InvalidCommandError < CommandError; end

    # Define allowed commands with their allowed arguments
    COMMAND_WHITELIST = {
      "git" => {
        "clone" => 2,      # url, path
        "remote" => 2..3,  # add/remove, name, [url]
        "add" => 1,        # path
        "commit" => 2,     # -m, message
        "push" => 2        # remote, branch
      },
      "bundle" => {
        "install" => 0,
        "exec" => 1
      },
      "bin/rails" => {
        "db:create" => 0,
        "db:migrate" => 0,
        "assets:precompile" => 0
      }
    }.freeze

    def self.execute(command, subcommand, *args, dir: nil)
      validate_command!(command, subcommand, args)
      Dir.chdir(dir || Dir.pwd) do
        # Convert args to an array and pass each argument individually
        cmd_args = [command, subcommand].concat(args.map(&:to_s))
        out, err, status = system(*cmd_args, out: :capture, err: :capture)
        unless status
          raise CommandError, "Command failed: #{err}"
        end
        out
      end
    end

    def self.validate_command!(command, subcommand, args)
      unless COMMAND_WHITELIST.key?(command)
        raise InvalidCommandError, "Command not allowed: #{command}"
      end

      allowed_args = COMMAND_WHITELIST[command][subcommand]
      case allowed_args
      when Integer
        unless args.length == allowed_args
          raise InvalidCommandError, "Invalid number of arguments"
        end
      when Range
        unless allowed_args.include?(args.length)
          raise InvalidCommandError, "Invalid number of arguments"
        end
      end

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