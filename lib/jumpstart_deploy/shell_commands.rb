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

      # Build command array without splat
      cmd_array = [command, subcommand].concat(args.map(&:to_s))

      Dir.chdir(dir || Dir.pwd) do
        env = { 'PATH' => '/usr/bin:/bin' }
        
        # Pass command and arguments directly to avoid shell interpretation
        read_pipe, write_pipe = IO.pipe
        
        pid = fork do
          read_pipe.close
          $stdout.reopen(write_pipe)
          $stderr.reopen(write_pipe)
          write_pipe.close

          # Clean environment and execute command
          ENV.clear
          ENV['PATH'] = '/usr/bin:/bin'
          
          # Execute with explicit command and arguments
          exec(
            cmd_array[0],
            *cmd_array[1..],
            unsetenv_others: true
          )
        end

        write_pipe.close
        output = read_pipe.read
        read_pipe.close

        _, status = Process.waitpid2(pid)
        
        unless status.success?
          # Log error internally but don't expose in message
          Rails.logger.error("Command error: #{output}") if defined?(Rails)
          raise CommandError, "Command '#{command} #{subcommand}' failed."
        end

        output
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