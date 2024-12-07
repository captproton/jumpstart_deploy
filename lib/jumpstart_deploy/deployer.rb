# frozen_string_literal: true

require "active_support/inflector"

module JumpstartDeploy
  class Deployer
    def initialize
      @prompt = TTY::Prompt.new
      @spinner = TTY::Spinner.new(":spinner :title", format: :dots)
      @github = Octokit::Client.new(access_token: fetch_github_token)
    end

    def deploy(options = {})
      configure_deployment(options)
      perform_deployment
    rescue StandardError => e
      handle_error(e)
    end

    private

    def configure_deployment(options)
      @app_name = options["name"]
      @team_name = options["team"]
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
      rescue Octokit::Conflict
        raise CommandError, "Repository already exists: #{@app_name}"
      rescue Octokit::Error => e
        raise CommandError, "GitHub repository creation failed: #{e.message}"
      end
    end

    def clone_jumpstart
      spinner_run("Cloning Jumpstart Pro") do
        jumpstart_url = fetch_jumpstart_url
        
        # Clone the repository
        ShellCommands.git("clone", jumpstart_url, tmp_path)
        
        # Configure remote
        ShellCommands.git("remote", "remove", "origin", dir: tmp_path)
        ShellCommands.git(
          "remote", 
          "add", 
          "origin", 
          @repo.ssh_url, 
          dir: tmp_path
        )
      end
    end

    def configure_jumpstart
      spinner_run("Configuring application") do
        # Update application name
        update_app_name

        # Install dependencies
        ShellCommands.bundle("install", dir: tmp_path)
        
        # Set up database
        ShellCommands.rails("db:create", dir: tmp_path)
        ShellCommands.rails("db:migrate", dir: tmp_path)

        # Commit changes
        ShellCommands.git("add", ".", dir: tmp_path)
        ShellCommands.git(
          "commit",
          "-m", "Initial Jumpstart Pro setup",
          dir: tmp_path
        )
        ShellCommands.git(
          "push",
          "-u", "origin", "main",
          dir: tmp_path
        )
      end
    end

    def update_app_name
      app_path = File.join(tmp_path, "config/application.rb")
      content = File.read(app_path)
      new_content = content.sub(
        /module \w+$/,
        "module #{@app_name.gsub("-", "_").camelize}"
      )
      File.write(app_path, new_content)
    end

    def setup_hatchbox
      spinner_run("Setting up Hatchbox") do
        create_hatchbox_app
        configure_environment
      end
    end

    def create_hatchbox_app
      response = HTTP.auth(fetch_hatchbox_token)
        .post("https://app.hatchbox.io/api/v1/apps",
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
      response = HTTP.auth(fetch_hatchbox_token)
        .post("https://app.hatchbox.io/api/v1/apps/#{@hatchbox_app["id"]}/env_vars",
          json: { env_vars: default_env_vars }
        )

      validate_response!(response)
    rescue HTTP::Error => e
      raise CommandError, "Hatchbox configuration failed: #{e.message}"
    end

    def add_team_to_repo
      @github.add_team_repository(
        @team_name,
        @repo.full_name,
        permission: "push"
      )
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

    def validate_response!(response)
      unless response.status.success?
        raise CommandError, "API request failed: #{response.body}"
      end
    end

    def fetch_github_token
      ENV.fetch("GITHUB_TOKEN") do
        raise CommandError, "GITHUB_TOKEN environment variable is not set"
      end
    end

    def fetch_hatchbox_token
      ENV.fetch("HATCHBOX_API_TOKEN") do
        raise CommandError, "HATCHBOX_API_TOKEN environment variable is not set"
      end
    end

    def fetch_jumpstart_url
      ENV.fetch("JUMPSTART_REPO_URL") do
        raise CommandError, "JUMPSTART_REPO_URL environment variable is not set"
      end
    end

    def default_env_vars
      {
        "RAILS_ENV" => "production",
        "RAILS_LOG_TO_STDOUT" => "true",
        "RAILS_SERVE_STATIC_FILES" => "true"
      }
    end

    def handle_error(error)
      case error
      when Octokit::Error
        raise CommandError, "GitHub Error: #{error.message}"
      when HTTP::Error
        raise CommandError, "Hatchbox Error: #{error.message}"
      else
        raise error
      end
    end

    def tmp_path
      @tmp_path ||= File.join(Dir.tmpdir, @app_name)
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