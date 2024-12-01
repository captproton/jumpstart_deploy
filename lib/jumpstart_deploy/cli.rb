# frozen_string_literal: true

require "thor"
require "octokit"
require "tty-prompt"
require "tty-spinner"
require "http"
require_relative "shell_commands"
require_relative "git_commands"

module JumpstartDeploy
  class CLI < Thor
    desc "new", "Create and deploy a new Jumpstart Pro app"
    method_option :name, type: :string, desc: "Name of the application"
    method_option :team, type: :string, desc: "GitHub team to grant access"
    def new
      deployer = Deployer.new
      deployer.deploy(options)
    end
  end

  class Deployer
    include GitCommands

    def initialize
      super()
      @prompt = TTY::Prompt.new
      @github = Octokit::Client.new(access_token: fetch_github_token)
      @spinner = TTY::Spinner.new(":spinner :title", format: :dots)
    end

    def deploy(options = {})
      configure_deployment(options)
      perform_deployment
    rescue StandardError => e
      handle_error(e)
    end

    private

    def configure_deployment(options)
      @app_name = options["name"] || 
                  @prompt.ask("What's the name of your app?", required: true)
      @team_name = options["team"] || 
                   @prompt.ask("GitHub team name (optional):")
      validate_inputs!
    end

    def validate_inputs!
      raise ArgumentError, "Invalid app name" unless valid_app_name?(@app_name)
      raise ArgumentError, "Invalid team name" if @team_name && !valid_team_name?(@team_name)
    end

    def valid_app_name?(name)
      name.match?(/\A[a-z0-9][a-z0-9-]*[a-z0-9]\z/) && name.length.between?(3, 63)
    end

    def valid_team_name?(name)
      name.match?(/\A[a-z0-9][a-z0-9-]*[a-z0-9]\z/)
    end

    def perform_deployment
      create_github_repo
      clone_jumpstart
      configure_jumpstart
      setup_hatchbox
      display_results
    end

    def create_github_repo
      spinner_run("Creating GitHub repository") do
        @repo = @github.create_repository(
          @app_name,
          private: true,
          description: "Rails application using Jumpstart Pro"
        )
        add_team_to_repo if @team_name
      end
    end

    def clone_jumpstart
      spinner_run("Cloning Jumpstart Pro") do
        jumpstart_url = fetch_jumpstart_url
        clone_repository(jumpstart_url, tmp_path)
        configure_remote(@repo.ssh_url, dir: tmp_path)
      end
    end

    def configure_jumpstart
      spinner_run("Configuring application") do
        Dir.chdir(tmp_path) do
          update_app_name
          ShellCommands.bundle("install")
          ShellCommands.rails("db:create", "db:migrate")
          initial_commit(dir: tmp_path)
        end
      end
    end

    def setup_hatchbox
      spinner_run("Setting up Hatchbox") do
        create_hatchbox_app
        configure_environment
      end
    end

    def create_hatchbox_app
      token = fetch_hatchbox_token
      response = HTTP.auth(token)
        .post(
          "https://app.hatchbox.io/api/v1/apps",
          json: {
            app: {
              name: @app_name,
              repository: @repo.full_name,
              framework: "rails"
            }
          }
        )
      
      validate_response!(response)
      @hatchbox_app = JSON.parse(response.body.to_s)
    end

    def configure_environment
      token = fetch_hatchbox_token
      response = HTTP.auth(token)
        .post(
          "https://app.hatchbox.io/api/v1/apps/#{@hatchbox_app["id"]}/env_vars",
          json: { env_vars: default_env_vars }
        )
      
      validate_response!(response)
    end

    def validate_response!(response)
      unless response.status.success?
        raise "API request failed: #{response.body}"
      end
    end

    def fetch_github_token
      ENV.fetch("GITHUB_TOKEN") do
        raise "GITHUB_TOKEN environment variable is not set"
      end
    end

    def fetch_hatchbox_token
      ENV.fetch("HATCHBOX_API_TOKEN") do
        raise "HATCHBOX_API_TOKEN environment variable is not set"
      end
    end

    def fetch_jumpstart_url
      ENV.fetch("JUMPSTART_REPO_URL") do
        raise "JUMPSTART_REPO_URL environment variable is not set"
      end
    end

    def default_env_vars
      {
        "RAILS_ENV" => "production",
        "RAILS_LOG_TO_STDOUT" => "true",
        "RAILS_SERVE_STATIC_FILES" => "true"
      }
    end

    def update_app_name
      content = File.read("config/application.rb")
      new_content = content.sub(
        /module \w+$/,
        "module #{@app_name.gsub("-", "_").camelize}"
      )
      File.write("config/application.rb", new_content)
    end

    def tmp_path
      @tmp_path ||= File.join(Dir.tmpdir, @app_name)
    end

    def spinner_run(title)
      @spinner.update(title: title)
      @spinner.auto_spin
      yield
      @spinner.success
    rescue StandardError => e
      @spinner.error
      raise e
    end

    def handle_error(error)
      @spinner.error("(#{error.message})")
      puts "\nDeployment failed. Please check the error and try again."
      cleanup
      raise error
    end

    def cleanup
      FileUtils.rm_rf(tmp_path) if Dir.exist?(tmp_path)
    end

    def display_results
      puts "\n✨ Deployment completed successfully!"
      puts "\nURLs:"
      puts "GitHub: #{@repo.html_url}"
      puts "Hatchbox: https://app.hatchbox.io/apps/#{@hatchbox_app["id"]}"
      puts "\nNext steps:"
      puts "1. Set up your database credentials in Hatchbox"
      puts "2. Configure any additional environment variables"
      puts "3. Trigger your first deployment"
    end
  end
end