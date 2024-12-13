# frozen_string_literal: true

require "tty-spinner"

module JumpstartDeploy
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
    end

    private

    def validate_step!(step)
      raise ArgumentError, "Invalid step: #{step}" unless STEPS.key?(step)
    end

    def ensure_started(step)
      start(step) unless @spinners[step]
    end
  end
end