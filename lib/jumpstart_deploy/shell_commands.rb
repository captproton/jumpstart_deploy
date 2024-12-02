# frozen_string_literal: true

require 'open3'
require 'English'
require 'securerandom'
require 'pathname'
require 'uri'
require 'tmpdir'
require 'fileutils'

module JumpstartDeploy
  module ShellCommands
    class CommandError < StandardError; end
    class InvalidCommandError < CommandError; end

    # Whitelist of allowed commands with strict argument patterns
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
          validator: ->(args) { args.length == 1 && valid_path?(args[0]) }
        },
        'commit' => {
          args: ['-m', :message],
          validator: ->(args) { args.length == 2 && args[0] == '-m' && safe_message?(args[1]) }
        },
        'push' => {
          args: [:remote, :branch],
          validator: ->(args) { args.length == 2 && valid_remote?(args[0]) && valid_branch?(args[1]) }
        }
      },
      'bundle' => {
        'install' => {
          args: [],
          validator: ->(args) { args.empty? }
        },
        'exec' => {
          args: [:command],
          validator: ->(args) { !args.empty? && valid_bundle_exec_command?(args) }
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

    class << self
      def execute(command, subcommand, *args, dir: nil)
        validate_command!(command, subcommand, args)

        # Generate a random temporary directory for each command execution
        temp_dir = Dir.mktmpdir("jumpstart_#{SecureRandom.hex(8)}_")

        begin
          # Change to temporary directory first, then to target directory
          Dir.chdir(temp_dir) do
            Dir.chdir(dir || Dir.pwd) do
              # Use Process.spawn with explicit argument passing and clean environment
              options = {
                unsetenv_others: true,  # Start with clean environment
                close_others: true      # Close all other file descriptors
              }

              # Create input/output pipes
              stdin_r, stdin_w = IO.pipe
              stdout_r, stdout_w = IO.pipe
              stderr_r, stderr_w = IO.pipe

              options[:in] = stdin_r
              options[:out] = stdout_w
              options[:err] = stderr_w

              # Spawn process with explicit arguments
              pid = Process.spawn({}, command, subcommand, *args, options)

              # Close write ends immediately
              stdin_w.close
              stdout_w.close
              stderr_w.close

              # Wait for process completion with timeout
              begin
                Timeout.timeout(300) do  # 5 minute timeout
                  _, status = Process.waitpid2(pid)

                  # Read output
                  stdout = stdout_r.read
                  stderr = stderr_r.read

                  # Clean up
                  [stdin_r, stdout_r, stderr_r].each(&:close)

                  unless status.success?
                    # Log error without exposing details
                    Rails.logger.error("Command error: #{stderr}") if defined?(Rails)
                    raise CommandError, "Command execution failed"
                  end

                  stdout
                end
              rescue Timeout::Error
                # Kill process if it times out
                Process.kill('TERM', pid)
                Process.waitpid(pid)
                raise CommandError, "Command execution timed out"
              end
            end
          end
        ensure
          # Always clean up temporary directory
          FileUtils.remove_entry_secure(temp_dir) if Dir.exist?(temp_dir)
        end
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

        validate_arguments!(args)
      end

      def validate_arguments!(args)
        args.each do |arg|
          # Normalize Unicode and validate characters
          normalized_arg = arg.to_s.unicode_normalize(:nfkc)
          unless normalized_arg.match?(/\A[\p{Word}\.\-\/]+\z/)
            raise InvalidCommandError, "Invalid characters in argument"
          end

          # Check for maximum argument length
          if normalized_arg.length > 1024
            raise InvalidCommandError, "Argument exceeds maximum length"
          end
        end
      end

      def safe_message?(message)
        return false if message.nil? || message.empty?
        normalized = message.to_s.unicode_normalize(:nfkc)
        # Allow printable characters but exclude potentially dangerous ones
        normalized.match?(/\A[\p{Print}&&[^;&|<>$`\\]]+\z/) &&
          normalized.length <= 1024  # Limit message length
      end

      def valid_git_url?(url)
        return false if url.nil? || url.empty?
        uri = URI.parse(url)
        valid_scheme = %w[http https ssh git].include?(uri.scheme)
        valid_host = !uri.host.nil? && !uri.host.empty?
        valid_length = url.length <= 2048  # Reasonable URL length limit

        valid_scheme && valid_host && valid_length
      rescue URI::InvalidURIError
        false
      end

      def valid_path?(path)
        return false if path.nil? || path.empty?
        path = Pathname.new(path)

        # Validate path characteristics
        !path.absolute? &&
          !path.each_filename.to_a.include?('..') &&
          path.to_s.match?(/\A[\p{Word}\.\-\/]+\z/) &&
          path.to_s.length <= 255  # Common filesystem path length limit
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

        # Only allow specific bundle exec commands
        whitelist = %w[rake rspec rubocop]
        command = args.first.to_s

        whitelist.include?(command) && command.length <= 255
      end
    end

    # Public interface methods
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
