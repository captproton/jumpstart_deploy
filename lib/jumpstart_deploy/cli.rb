# frozen_string_literal: true

require "thor"
require "tty-prompt"

module JumpstartDeploy
  class CLI < Thor
    Error = Class.new(StandardError)

    def self.exit_on_failure?
      true
    end

    def initialize(*args)
      super
      @prompt = TTY::Prompt.new
    end

    desc "new", "Create and deploy a new Jumpstart Pro app"
    method_option :name, type: :string, desc: "Name of the application"
    method_option :team, type: :string, desc: "GitHub team to grant access"
    def new(options = {})
      deployer = Deployer.new
      options = parse_and_validate_options(options)
      deployer.deploy(options)
    end

    desc "test_signal", "Test signal handling"
    def test_signal
      puts "Press Ctrl+C to test signal handling..."
      sleep 10
      puts "If you see this, signal handling didn't work!"
    end

    private

    def parse_and_validate_options(options)
      # First validate/get app name
      name = options["name"] || prompt_name
      validate_app_name!(name)

      # Then handle team name if valid
      team = options["team"] || prompt_team
      validate_team_name!(team) if team

      { "name" => name, "team" => team }
    end

    def prompt_name
      @prompt.ask("What's the name of your app?", required: true)
    end

    def prompt_team
      @prompt.ask("GitHub team name (optional):")
    end

    def validate_app_name!(name)
      unless name.match?(/\A[a-z0-9][a-z0-9-]*[a-z0-9]\z/)
        raise ArgumentError, "Invalid app name. Use lowercase letters, numbers, and hyphens"
      end
    end

    def validate_team_name!(team)
      unless team.match?(/\A[a-z0-9][a-z0-9-]*[a-z0-9]\z/)
        raise ArgumentError, "Invalid team name. Use lowercase letters, numbers, and hyphens"
      end
    end
  end
end
