# frozen_string_literal: true

require "thor"
require "octokit"
require "tty-prompt"
require "tty-spinner"
require "http"

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
    def initialize
      super
      @prompt = TTY::Prompt.new
      @github = Octokit::Client.new(access_token: ENV.fetch("GITHUB_TOKEN"))
      @spinner = TTY::Spinner.new(":spinner :title", format: :dots)
    end

    def deploy(options = {})
      @app_name = options["name"] || @prompt.ask("What's the name of your app?", required: true)
      @team_name = options["team"] || @prompt.ask("GitHub team name (optional):")

      begin
        create_github_repo
        clone_jumpstart
        configure_jumpstart
        setup_hatchbox
        display_results
      rescue StandardError => e
        @spinner.error("(#{e.message})")
        puts "\nDeployment failed. Please check the error and try again."
      end
    end

    private

    def create_github_repo
      spinner_run("Creating GitHub repository") do
        @repo = @github.create_repository(
          @app_name,
          private: true,
          description: "Rails application using Jumpstart Pro"
        )
      end
      
      add_team_to_repo if @team_name
    end

    def clone_jumpstart
      spinner_run("Cloning Jumpstart Pro") do
        system("git clone #{ENV.fetch("JUMPSTART_REPO_URL")} #{tmp_path}")
        Dir.chdir(tmp_path) do
          system("git remote remove origin")
          system("git remote add origin #{@repo.ssh_url}")
        end
      end
    end

    def configure_jumpstart
      spinner_run("Configuring application") do
        Dir.chdir(tmp_path) do
          update_app_name
          system("bundle install")
          system("bin/rails db:create db:migrate")
          system("git add .")
          system("git commit -m 'Initial Jumpstart Pro setup'")
          system("git push -u origin main")
        end
      end
    end

    def setup_hatchbox
      spinner_run("Setting up Hatchbox") do
        response = HTTP.auth(ENV.fetch("HATCHBOX_API_TOKEN"))
          .post("https://app.hatchbox.io/api/v1/apps", json: {
            app: {
              name: @app_name,
              repository: @repo.full_name,
              framework: "rails"
            }
          })

        @hatchbox_app = JSON.parse(response.body.to_s)
        
        # Configure environment variables
        HTTP.auth(ENV.fetch("HATCHBOX_API_TOKEN"))
          .post("https://app.hatchbox.io/api/v1/apps/#{@hatchbox_app["id"]}/env_vars", json: {
            env_vars: default_env_vars
          })
      end
    end

    def add_team_to_repo
      spinner_run("Adding team access") do
        @github.add_team_repository(
          @team_name,
          @repo.full_name,
          permission: "push"
        )
      end
    end

    def update_app_name
      application_rb = File.read("config/application.rb")
      new_module_name = @app_name.gsub("-", "_").camelize
      updated_content = application_rb.gsub(/module \w+$/, "module #{new_module_name}")
      File.write("config/application.rb", updated_content)
    end

    def default_env_vars
      {
        "RAILS_ENV" => "production",
        "RAILS_LOG_TO_STDOUT" => "true",
        "RAILS_SERVE_STATIC_FILES" => "true"
      }
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