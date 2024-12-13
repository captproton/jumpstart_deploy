<<<<<<< HEAD
=======
# lib/jumpstart_deploy/deployment_progress.rb
>>>>>>> 19c95f3624e2ee776253c19602f4f0d8b3df7eea
# frozen_string_literal: true

require "tty-spinner"

module JumpstartDeploy
<<<<<<< HEAD
  class DeploymentProgress
    STEPS = {
      github_setup: "Creating GitHub repository",
      app_setup: "Configuring application"
    }.freeze

    def initialize
      @spinners = {}
      @step_statuses = {}
    end

    def start(step)
      validate_step!(step)
      return if @spinners[step]

      @spinners[step] = TTY::Spinner.new("[:spinner] #{STEPS[step]}")
      @spinners[step].auto_spin
    end

    def success(step)
      validate_step!(step)
      ensure_started(step)
      @step_statuses[step] = :complete
      @spinners[step].success
    end

    def error(step, error)
      validate_step!(step)
      ensure_started(step)
      @step_statuses[step] = :failed
      @spinners[step].error
      puts "\nError during #{STEPS[step].downcase}:"
      puts error.message
=======
  # Handles deployment progress feedback and status tracking
  # Follows Single Responsibility Principle - only manages progress display
  class DeploymentProgress
    STEPS = {
      github_setup: "Creating GitHub repository",
      clone_template: "Cloning Jumpstart Pro template",
      configure_app: "Configuring application",
      hatchbox_setup: "Setting up Hatchbox application",
      deploy: "Deploying application"
    }.freeze

    attr_reader :step_statuses, :current_step

    def initialize
      @spinners = TTY::Spinner::Multi.new("[:spinner] Deployment Progress:", format: :dots_2)
      @step_statuses = {}
      setup_spinners
    end

    def start_step(step)
      validate_step!(step)
      @current_step = step
      sp = @spinners[step]
      sp.auto_spin
    end

    def complete_step(step)
      validate_step!(step)
      @step_statuses[step] = :complete
      sp = @spinners[step]
      sp.success
    end

    def fail_step(step, error)
      validate_step!(step)
      @step_statuses[step] = :failed
      sp = @spinners[step]
      sp.error
      handle_failure(step, error)
    end

    def summary
      puts "\nDeployment Status:"
      @step_statuses.each do |step, status|
        status_icon = status == :complete ? "✓" : "✗"
        puts "#{status_icon} #{STEPS[step]}"
      end
>>>>>>> 19c95f3624e2ee776253c19602f4f0d8b3df7eea
    end

    private

<<<<<<< HEAD
=======
    def setup_spinners
      STEPS.each do |step, message|
        @spinners.register(:"#{step}") do |spinner|
          spinner.update(title: message)
        end
      end
    end

>>>>>>> 19c95f3624e2ee776253c19602f4f0d8b3df7eea
    def validate_step!(step)
      raise ArgumentError, "Invalid step: #{step}" unless STEPS.key?(step)
    end

<<<<<<< HEAD
    def ensure_started(step)
      start(step) unless @spinners[step]
    end
  end
end
=======
    def handle_failure(step, error)
      puts "\nError during #{STEPS[step].downcase}:"
      puts error.message
      puts "\nTroubleshooting steps:"

      case step
      when :github_setup
        puts "- Verify your GitHub access token is valid"
        puts "- Check if repository name is available"
        puts "- Ensure you have sufficient GitHub permissions"
      when :clone_template
        puts "- Verify Jumpstart Pro credentials"
        puts "- Check network connectivity"
        puts "- Ensure sufficient disk space"
      when :configure_app
        puts "- Check application name format"
        puts "- Verify database configuration"
        puts "- Review Rails environment setup"
      when :hatchbox_setup
        puts "- Verify Hatchbox API token"
        puts "- Check Hatchbox account permissions"
        puts "- Review application configuration"
      when :deploy
        puts "- Check deployment logs"
        puts "- Verify environment variables"
        puts "- Review application settings"
      end

      summary
      exit(1)
    end
  end
end
>>>>>>> 19c95f3624e2ee776253c19602f4f0d8b3df7eea
