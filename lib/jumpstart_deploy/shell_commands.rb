# frozen_string_literal: true

require "tty-command"
require "shellwords"
require "pathname"
require "uri"

module JumpstartDeploy
  module ShellCommands
    class CommandError < StandardError; end
    class InvalidCommandError < CommandError; end

    COMMAND_WHITELIST = {
      "git" => {
        "clone" => {
          args: 2,      # url, path
          validator: ->(args) { valid_git_url?(args[0]) && valid_path?(args[1]) }
        },
        "remote" => {
          args: 2..3,  # add/remove, name, [url]
          validator: ->(args) { %w[add remove].include?(args[0]) && valid_remote_args?(args) }
        },
        "add" => {
          args: 1..2,     # [options], path
          validator: ->(args) { valid_path?(args[-1]) }
        },
        "commit" => {
          args: 2,     # -m, message
          validator: ->(args) { args[0] == "-m" && safe_message?(args[1]) }
        },
        "push" => {
          args: 2..3,     # [-u], origin, main
          validator: ->(args) { valid_push_args?(args) }
        }
      },
      "bundle" => {
        "install" => {
          args: 0,
          validator: ->(args) { args.empty? }
        },
        "exec" => {
          args: 1..Float::INFINITY,
          validator: ->(args) { !args.empty? && valid_bundle_exec_command?(args) }
        }
      },
      "bin/rails" => {
        "db:create" => {
          args: 0,
          validator: ->(args) { args.empty? }
        },
        "db:migrate" => {
          args: 0,
          validator: ->(args) { args.empty? }
        },
        "assets:precompile" => {
          args: 0,
          validator: ->(args) { args.empty? }
        }
      }
    }.freeze

    WHITELISTED_BUNDLE_COMMANDS = %w[rake rspec rubocop].freeze

    class << self
      def execute(command, subcommand, *args, dir: nil)
        validate_command!(command, subcommand, args)

        cmd = TTY::Command.new(printer: :null)
        
        Dir.chdir(dir || Dir.pwd) do
          result = cmd.run!(command, subcommand, *args)
          result.out.to_s
        end
      rescue TTY::Command::ExitError => e
        Rails.logger.error("Command failed: #{e.result.err}") if defined?(Rails)
        raise CommandError, "Command failed: #{e.result.err}"
      end

      def git(subcommand, *args, dir: nil)
        execute("git", subcommand, *args, dir: dir)
      end

      def rails(subcommand, *args, dir: nil)
        execute("bin/rails", subcommand, *args, dir: dir)
      end

      def bundle(subcommand, *args, dir: nil)
        execute("bundle", subcommand, *args, dir: dir)
      end

      private

      def validate_command!(command, subcommand, args)
        unless COMMAND_WHITELIST.key?(command)
          raise InvalidCommandError, "Command not allowed: #{command}"
        end

        config = COMMAND_WHITELIST[command]
        unless config.key?(subcommand)
          raise InvalidCommandError, "Subcommand not allowed: #{subcommand} for #{command}"
        end

        cmd_config = config[subcommand]
        
        # Check argument count
        case cmd_config[:args]
        when Integer
          unless args.length == cmd_config[:args]
            raise InvalidCommandError, "Invalid number of arguments for #{subcommand} (expected #{cmd_config[:args]}, got #{args.length})"
          end
        when Range
          unless cmd_config[:args].include?(args.length)
            raise InvalidCommandError, "Invalid number of arguments for #{subcommand} (expected #{cmd_config[:args]}, got #{args.length})"
          end
        end

        # Validate arguments for dangerous content
        validate_arguments!(args)

        # Run command-specific validation
        unless cmd_config[:validator].call(args)
          raise InvalidCommandError, "Invalid arguments for #{subcommand}"
        end
      end

      def validate_arguments!(args)
        args.each do |arg|
          if arg.to_s.match?(/[;&|<>$`\\]/) || arg.to_s.include?("rm -rf")
            raise InvalidCommandError, "Invalid characters in argument: #{arg}"
          end
        end
      end

      def valid_git_url?(url)
        return false if url.nil? || url.empty?
        uri = URI.parse(url)
        valid_scheme = %w[http https ssh git].include?(uri.scheme)
        valid_host = !uri.host.nil? && !uri.host.empty?
        valid_scheme && valid_host
      rescue URI::InvalidURIError
        false
      end

      def valid_path?(path)
        return false if path.nil? || path.empty?
        
        # Convert to pathname for validation
        path = Pathname.new(path)
        
        # Check for path traversal attempts
        return false if path.absolute? || path.each_filename.to_a.include?("..")
        
        # Check characters
        path.to_s.match?(/\A[\w\-\.\/]+\z/)
      end

      def valid_remote?(remote)
        return false if remote.nil? || remote.empty?
        remote.match?(/\A[\w\-\.]+\z/)
      end

      def valid_branch?(branch)
        return false if branch.nil? || branch.empty?
        branch.match?(/\A[\w\-\.\/]+\z/)
      end

      def valid_remote_args?(args)
        case args[0]
        when "add"
          args.length == 3 && valid_remote?(args[1])
        when "remove"
          args.length == 2 && valid_remote?(args[1])
        else
          false
        end
      end

      def valid_push_args?(args)
        if args[0] == "-u"
          args.length == 3 && valid_remote?(args[1]) && valid_branch?(args[2])
        else
          args.length == 2 && valid_remote?(args[0]) && valid_branch?(args[1])  
        end
      end

      def valid_bundle_exec_command?(args)
        return false if args.empty?
        WHITELISTED_BUNDLE_COMMANDS.include?(args.first.to_s)
      end

      def safe_message?(message)
        return false if message.nil? || message.empty?
        message.match?(/\A[\p{Print}&&[^;&|<>$`\\]]+\z/)
      end
    end
  end
end