# frozen_string_literal: true

require 'open3'

module JumpstartDeploy
  module ShellCommands
    class CommandError < StandardError; end
    class InvalidCommandError < CommandError; end

    # Define command configurations with their exact argument patterns
    COMMAND_CONFIG = {
      'git' => {
        'clone' => {
          args: [:url, :path],
          validator: ->(args) { valid_git_url?(args[0]) && valid_path?(args[1]) }
        },
        'remote' => {
          args: [:action, :name, :url],
          validator: ->(args) { %w[add remove].include?(args[0]) && args.length.between?(2, 3) }
        },
        'add' => {
          args: [:path],
          validator: ->(args) { args.length == 1 }
        },
        'commit' => {
          args: ['-m', :message],
          validator: ->(args) { args.length == 2 && args[0] == '-m' && safe_message?(args[1]) }
        },
        'push' => {
          args: [:remote, :branch],
          validator: ->(args) { args.length == 2 }
        }
      },
      'bundle' => {
        'install' => {
          args: [],
          validator: ->(args) { args.empty? }
        },
        'exec' => {
          args: [:command],
          validator: ->(args) { !args.empty? }
        }
      },
      'bin/rails' => {
        'db:create' => {
          args: [],
          validator: ->(args) { args.empty? }
        },
        'db:migrate' => {
          args: [],
          validator: ->(args) { args.empty? }
        },
        'assets:precompile' => {
          args: [],
          validator: ->(args) { args.empty? }
        }
      }
    }.freeze

    def self.execute(command, subcommand, *args, dir: nil)
      validate_command!(command, subcommand, args)
      
      Dir.chdir(dir || Dir.pwd) do
        # Following the documentation pattern exactly:
        # system("command", "arg1", "arg2")
        stdout, stderr, status = Open3.capture3(command, subcommand, *args)
        unless status.success?
          # Log error internally but don't expose in message
          Rails.logger.error("Command error: #{stderr}") if defined?(Rails)
          raise CommandError, "Command '#{command} #{subcommand}' failed."
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
        normalized_arg = arg.to_s.unicode_normalize(:nfkc)
        unless normalized_arg.match?(/\A[\w\.\-\/]+\z/)
          raise InvalidCommandError, "Invalid characters in argument: #{arg}"
        end
      end
    end

    def self.safe_message?(message)
      # Define allowed patterns or escape the message safely
      # For example, reject messages containing control characters
      !message.to_s.match?(/[\x00-\x1F\x7F]/)
    end

    def self.valid_git_url?(url)
      uri = URI.parse(url)
      %w[http https ssh git].include?(uri.scheme)
    rescue URI::InvalidURIError
      false
    end

    def self.valid_path?(path)
      # Ensure the path is a relative path and does not traverse directories
      !path.include?('..') && path.match?(/\A[\w\.\-\/]+\z/)
    end

    def self.git(subcommand, *args, dir: nil)
      execute('git', subcommand, *args, dir: dir)
    end

    def self.rails(subcommand, *args, dir: nil)
      execute('bin/rails', subcommand, *args, dir: dir)
    end

    def self.bundle(subcommand, *args, dir: nil)
      execute('bundle', subcommand, *args, dir: dir)
    end
  end
end