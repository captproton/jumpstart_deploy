# lib/jumpstart_deploy/shell_commands.rb
# frozen_string_literal: true

require "open3"

module JumpstartDeploy
  module ShellCommands
    class CommandError < StandardError; end
    class InvalidCommandError < CommandError; end

<<<<<<< HEAD
    ALLOWED_COMMANDS = ["git", "bundle", "bin/rails"].freeze
=======
    COMMAND_CONFIG = {
      "git" => {
        "clone" => {
          args: [ :url, :path ],
          validator: ->(args) { valid_git_url?(args[0]) && valid_path?(args[1]) }
        },
        "remote" => {
          args: [ :action, :name, :url ],
          validator: ->(args) { %w[add remove].include?(args[0]) && args.length.between?(2, 3) }
        },
        "add" => {
          args: [ :path ],
          validator: ->(args) { args.length == 1 && valid_path?(args[0]) }
        },
        "commit" => {
          args: [ "-m", :message ],
          validator: ->(args) { args.length == 2 && args[0] == "-m" && safe_message?(args[1]) }
        },
        "push" => {
          args: [ :flags, :remote, :branch ],
          validator: ->(args) {
            return false if args.empty?
            if args[0] == "-u"
              args.length == 3 && valid_remote?(args[1]) && valid_branch?(args[2])
            else
              args.length == 2 && valid_remote?(args[0]) && valid_branch?(args[1])
            end
          }
        }
      },
      "bundle" => {
        "install" => {
          args: [],
          validator: ->(args) { args.empty? }
        },
        "exec" => {
          args: [ :command ],
          validator: ->(args) { !args.empty? && valid_bundle_exec_command?(args) }
        }
      },
      "bin/rails" => {
        "db:create" => {
          args: [],
          validator: ->(args) { args.empty? }
        },
        "db:migrate" => {
          args: [],
          validator: ->(args) { args.empty? }
        },
        "assets:precompile" => {
          args: [],
          validator: ->(args) { args.empty? }
        }
      }
    }.freeze
>>>>>>> 19c95f3624e2ee776253c19602f4f0d8b3df7eea

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
<<<<<<< HEAD
        stdout
=======
      rescue TTY::Command::ExitError => e
        Rails.logger.error("Command error: #{e.message}") if defined?(Rails)
        raise CommandError.new(e.message.to_s)
      end

      private

      def validate_command!(command, subcommand, args)
        unless COMMAND_CONFIG.key?(command)
          raise InvalidCommandError, "Command not allowed: #{command}"
        end

        cmd_configs = COMMAND_CONFIG[command]
        unless cmd_configs.key?(subcommand)
          raise InvalidCommandError, "Subcommand not allowed: #{subcommand}"
        end

        config = cmd_configs[subcommand]
        unless config[:validator].call(args)
          raise InvalidCommandError, "Invalid arguments"
        end
      end

      def safe_message?(message)
        return false if message.nil? || message.empty?
        message.match?(/\A[\p{Print}&&[^;&|<>$`\\]]+\z/) && message.length <= 1024
      end

      def valid_git_url?(url)
        return false if url.nil? || url.empty?
        uri = URI.parse(url)
        valid_scheme = %w[http https ssh git].include?(uri.scheme)
        valid_host = !uri.host.nil? && !uri.host.empty?
        valid_length = url.length <= 2048

        valid_scheme && valid_host && valid_length
      rescue URI::InvalidURIError
        false
      end

      def valid_path?(path)
        return false if path.nil? || path.empty?
        path = Pathname.new(path)

        !path.absolute? &&
          !path.each_filename.to_a.include?("..") &&
          path.to_s.match?(/\A[\p{Word}\.\-\/]+\z/) &&
          path.to_s.length <= 255
      end

      def valid_remote?(remote)
        return false if remote.nil? || remote.empty?
        remote.match?(/\A[\p{Word}\.\-]+\z/) && remote.length <= 255
      end

      def valid_branch?(branch)
        return false if branch.nil? || branch.empty?
        branch.match?(/\A[\p{Word}\.\-\/]+\z/) && branch.length <= 255
      end

      def valid_bundle_exec_command?(args)
        return false if args.empty?
        whitelist = %w[rake rspec rubocop]
        command = args.first.to_s
        whitelist.include?(command) && command.length <= 255
>>>>>>> 19c95f3624e2ee776253c19602f4f0d8b3df7eea
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