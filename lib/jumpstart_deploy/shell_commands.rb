# frozen_string_literal: true

module JumpstartDeploy
  module ShellCommands
    class CommandError < StandardError; end
    class InvalidCommandError < CommandError; end

    # Define command configurations with their exact argument patterns
    COMMAND_CONFIG = {
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

    def self.execute(command, subcommand, *args, dir: nil)
      cmd_config = validate_and_get_config!(command, subcommand, args)
      cmd_array = build_command_array(command, subcommand, args, cmd_config)

      run_command(cmd_array, dir)
    end

    def self.validate_and_get_config!(command, subcommand, args)
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

      config
    end

    def self.build_command_array(command, subcommand, args, config)
      [command, subcommand, *process_arguments(args)].compact
    end

    def self.process_arguments(args)
      args.map(&:to_s).map do |arg|
        if arg.match?(/[;&|]/)
          raise InvalidCommandError, "Invalid characters in argument"
        end
        arg
      end
    end

    def self.run_command(cmd_array, dir = nil)
      working_dir = dir || Dir.pwd
      out_r, out_w = IO.pipe
      err_r, err_w = IO.pipe
      
      Dir.chdir(working_dir) do
        pid = Process.spawn(
          cmd_array[0],           # command
          *cmd_array[1..],        # arguments
          {
            out: out_w,           # redirect stdout
            err: err_w,           # redirect stderr
            unsetenv_others: true # clean environment
          }
        )
        
        out_w.close
        err_w.close
        
        _, status = Process.waitpid2(pid)
        output = out_r.read
        error = err_r.read
        
        unless status.success?
          raise CommandError, "Command failed: #{error}"
        end
        
        output
      ensure
        [out_r, err_r].each(&:close)
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