# frozen_string_literal: true

module JumpstartDeploy
  class Deployer
    attr_reader :repository

    def initialize
      @github_client = GitHub::Client.new
      @hatchbox_client = Hatchbox::Client.new
      @progress = DeploymentProgress.new
      @repository = nil
    end

    def deploy(options)
      validate_options!(options)
      
      @progress.start(:github_setup)
      create_github_repo(options)
      @progress.success(:github_setup)
      
      @progress.start(:app_setup)
      setup_template(options)
      setup_hatchbox(options)
      @progress.success(:app_setup)

    rescue StandardError => e
      handle_error(e)
      raise
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
    rescue StandardError => e
      @progress.error(:github_setup, e)
      raise
    end

    def setup_template(options)
      ShellCommands.git(
        "clone",
        ENV.fetch("JUMPSTART_REPO_URL"),
        options["name"]
      )
    end

    def setup_hatchbox(options = {})
      response = @hatchbox_client.create_application(
        name: options["name"],
        repository: @repository&.full_name,
        framework: "rails"
      )

      return unless response && response["id"]

      @hatchbox_client.post("#{response['id']}/env_vars", json: {
        env_vars: default_env_vars
      })
    end

    def handle_error(error)
      case error
      when Octokit::Conflict
        raise CommandError, "Repository already exists: #{error.message}"
      when Octokit::Error
        raise CommandError, "GitHub error: #{error.message}"
      when HTTP::Error
        raise CommandError, "Hatchbox configuration failed: #{error.message}"
      end
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