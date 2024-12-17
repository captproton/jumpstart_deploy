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
      
      setup_github(options)
      setup_application(options)
      trigger_deployment(options)

      @progress.summary
    rescue StandardError => e
      @progress.summary
      raise
    end

    private

    def validate_options!(options)
      raise Error, "Name is required" unless options["name"]
    end

    def setup_github(options)
      @progress.start_step(:github_setup)
      @repository = @github_client.create_repository(
        name: options.fetch("name"),
        private: true,
        description: "Rails application using Jumpstart Pro"
      )

      @github_client.add_team_to_repository(options["team"], @repository.full_name) if options["team"]
      @progress.complete_step(:github_setup)
    rescue StandardError => e
      @progress.fail_step(:github_setup, e)
      raise
    end

    def setup_application(options)
      clone_template(options)
      configure_template(options)
      setup_hatchbox(options)
    end

    def clone_template(options)
      @progress.start_step(:clone_template)
      ShellCommands.git(
        "clone",
        ENV.fetch("JUMPSTART_REPO_URL"),
        options["name"]
      )
      @progress.complete_step(:clone_template)
    rescue StandardError => e
      @progress.fail_step(:clone_template, e)
      raise
    end

    def configure_template(options)
      @progress.start_step(:configure_app)
      Dir.chdir(options["name"]) do
        ShellCommands.bundle("install")
        ShellCommands.rails("db:create", "db:migrate")
      end
      @progress.complete_step(:configure_app)
    rescue StandardError => e
      @progress.fail_step(:configure_app, e)
      raise
    end

    def setup_hatchbox(options)
      @progress.start_step(:hatchbox_setup)
      response = @hatchbox_client.create_application(
        name: options["name"],
        repository: @repository&.full_name,
        framework: "rails"
      )

      if response && response["id"]
        @hatchbox_client.configure_environment(
          response["id"], 
          env_vars: default_env_vars
        )
      end
      @progress.complete_step(:hatchbox_setup)
    rescue StandardError => e
      @progress.fail_step(:hatchbox_setup, e)
      raise
    end

    def trigger_deployment(options)
      @progress.start_step(:deploy)
      @hatchbox_client.deploy(
        name: options["name"],
        branch: options.fetch("branch", "main")
      )
      @progress.complete_step(:deploy)
    rescue StandardError => e
      @progress.fail_step(:deploy, e)
      raise
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