# frozen_string_literal: true

require "thor"

module JumpstartDeploy
  class CLI < Thor
    desc "new", "Create and deploy a new Jumpstart Pro app"
    method_option :name, type: :string, desc: "Name of the application"
    method_option :team, type: :string, desc: "GitHub team to grant access"
    def new(options = {})
      # Initialize components
      @prompt = TTY::Prompt.new
      deployer = Deployer.new

      # Collect and validate options
      deploy_options = validate_options(options)

      # Execute deployment
      deployer.deploy(deploy_options)
    end

    private

    def validate_options(options)
      validated = {}
      
      # Validate app name
      name = options["name"] || @prompt.ask("What's the name of your app?", required: true)
      validate_app_name!(name)
      validated["name"] = name

      # Validate team name if provided
      team = options["team"] || @prompt.ask("GitHub team name (optional):")
      if team && !team.empty?
        validate_team_name!(team)
        validated["team"] = team
      end

      validated
    end

    def validate_app_name!(name)
      unless name.match?(/\A[a-z0-9][a-z0-9_]*[a-z0-9]\z/) && name.length.between?(3, 63)
        raise ArgumentError, "Invalid app name: must be 3-63 characters, lowercase alphanumeric and underscores only"
      end
    end

    def validate_team_name!(team)
      unless team.match?(/\A[a-z0-9][a-z0-9\-]*[a-z0-9]\z/)
        raise ArgumentError, "Invalid team name: must be lowercase alphanumeric and hyphens only"
      end
    end
  end
end