# frozen_string_literal: true

module JumpstartDeploy
  module ShellCommands
    class CommandError < StandardError; end
    class InvalidCommandError < CommandError; end

    # Define allowed commands with their allowed arguments
    COMMAND_WHITELIST = {
      "git" => {
        "clone" => {
          args: [:url, :path],
          validator: ->(args) { args.length == 2 }
        },
        "remote" => {
          args: [:action, :name, :url],
          validator: ->(args) { ["add", "remove"].include?(args[0]) && args.length.between?(2, 3) }
        },
        "add" => {
          args: [:path],
          validator: ->(args) { args.length == 1 }
        },
        "commit" => {
          args: ["-m", :message],
          validator: ->(args) { args.length == 2 && args[0] == "-m" }
        },
        "push" => {
          args: [:remote, :branch],
          validator: ->(args) { args.length == 2 }
        }
      },
      "bundle" => {
        "install" => {
          args: [],
          validator: ->(args) { args.empty? }
        },
        "exec" => {
          args: [:command],
          validator: ->(args) { !args.empty? }
        }
      },
      "bin/rails" => {
        "db:create" => 0,
        "db:migrate" => 0,
        "assets:precompile" => 0
      }
    }.freeze

    def self.execute(command, subcommand, *args, dir: nil)
      validate_command!(command, subcommand, args)

      # Build the command array safely
      cmd_array = [command, subcommand, *args].map(&:to_s)

      Dir.chdir(dir || Dir.pwd) do
        stdout, stderr, status = Open3.capture3(*cmd_array)
        unless status.success?
          raise CommandError, "Command failed: #{stderr.strip}"
        end
        stdout
      end
    end

    def self.validate_command!(command, subcommand, args)
      unless COMMAND_CONFIG.key?(command)
        raise InvalidCommandError, "Command not allowed: #{command}"
      end

      cmd_configs = COMMAND_CONFIG[command]
      unless cmd_configs.key?(subcommand)
        raise InvalidCommandError, "Subcommand not allowed: #{subcommand} for #{command}"
      end

      config = cmd_configs[subcommand]
      unless config[:validator].call(args)
        raise InvalidCommandError, "Invalid arguments for #{command} #{subcommand}"
      end

      validate_arguments!(args)
    end

    def self.validate_arguments!(args)
      args.each do |arg|
        if arg.to_s.match?(/[;&|]/)
          raise InvalidCommandError, "Invalid characters in argument: #{arg}"
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
