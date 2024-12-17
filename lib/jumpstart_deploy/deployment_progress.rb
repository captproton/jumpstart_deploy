# frozen_string_literal: true

require "tty-spinner"

module JumpstartDeploy
  # Handles deployment progress feedback and status tracking
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
      @spinners = TTY::Spinner::Multi.new("[:spinner] Deployment Progress")
      @registered_spinners = {}  # Track spinners by step
      @step_statuses = {}
      setup_spinners
    end

    def start_step(step)
      validate_step!(step)
      @current_step = step
      spinner_for(step).auto_spin
    end

    def complete_step(step)
      validate_step!(step)
      @step_statuses[step] = :complete 
      spinner_for(step).success
    end

    def fail_step(step, error)
      validate_step!(step)
      @step_statuses[step] = :failed
      spinner_for(step).error
      handle_failure(step, error)
    end

    def interrupt_step(step, message)
      validate_step!(step)
      @step_statuses[step] = :interrupted
      spinner_for(step).error("Interrupted")
      puts "\nDeployment interrupted: #{message}"
    end

    def summary
      puts "\nDeployment Status:"
      @step_statuses.each do |step, status|
        status_icon = case status
                     when :complete then "✓"
                     when :interrupted then "⚠"
                     else "✗"
                     end
        puts "#{status_icon} #{STEPS[step]}"
      end
    end

    private

    def setup_spinners
      STEPS.each do |step, message|
        spinner = @spinners.register(step)
        spinner.update(title: message)
        @registered_spinners[step] = spinner
      end
    end

    def spinner_for(step)
      validate_step!(step)
      @registered_spinners[step]
    end

    def validate_step!(step)
      raise ArgumentError, "Invalid step: #{step}" unless STEPS.key?(step)
    end

    def handle_failure(step, error)
      puts "\nError during #{STEPS[step]}:"
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
    end
  end
end