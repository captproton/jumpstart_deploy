# frozen_string_literal: true

module JumpstartDeploy
  class Deployer
    attr_reader :repository

    def initialize
      @github_client = GitHub::Client.new
      @hatchbox_client = Hatchbox::Client.new
      @repository = nil
    end

    def deploy(options)
      validate_options!(options)
      
      create_github_repo(options)
      setup_template(options)
      setup_hatchbox(options)
    rescue Octokit::Conflict => e
      raise CommandError, "Repository already exists: #{e.message}"
    rescue Octokit::Error => e
      raise CommandError, "GitHub error: #{e.message}"
    rescue HTTP::Error => e
      raise CommandError, "Hatchbox configuration failed: #{e.message}"
    end

    private

    def validate_options!(options)
      raise Error, "Name is required" unless options["name"]
    end

    def create_github_repo(options = {})
      @repository = @github_client.create_repository(
        name: options.fetch("name"),
        private: true,
        description: "Rails application using Jumpstart Pro"
      )

      @github_client.add_team_to_repository(options["team"], @repository.full_name) if options["team"]
      @repository
    end

    def setup_template(options)
      ShellCommands.git(
        "clone",
        ENV.fetch("JUMPSTART_REPO_URL"),
        options["name"]
      )
    end

    def setup_hatchbox(options = {})
      # First create the application
      response = @hatchbox_client.create_application(
        name: options["name"],
        repository: @repository&.full_name,
        framework: "rails"
      )

      # Then set up environment variables
      @hatchbox_client.post("#{response['id']}/env_vars", json: {
        env_vars: default_env_vars
      })
    end

    def default_env_vars
      {
        "RAILS_ENV" => "production",
        "RAILS_LOG_TO_STDOUT" => "true",
        "RAILS_SERVE_STATIC_FILES" => "true"
      }
    end
  end
end