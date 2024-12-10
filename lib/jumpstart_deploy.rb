# frozen_string_literal: true

# Core dependencies
require "tty-command"
require "tty-prompt"
require "tty-spinner"
require "octokit"
require "faraday"
require "json"

# Define base error first
module JumpstartDeploy
  class Error < StandardError; end
  class CommandError < Error; end
end

# Base functionality
require "jumpstart_deploy/version"
require "jumpstart_deploy/shell_commands"

# Errors (must be loaded before components that use them)
require "jumpstart_deploy/hatchbox/errors"

# Hatchbox components (order matters for dependencies)
require "jumpstart_deploy/hatchbox/application"
require "jumpstart_deploy/hatchbox/connection"
require "jumpstart_deploy/hatchbox/deployment"
require "jumpstart_deploy/hatchbox/client"

# Progress tracking and CLI
require "jumpstart_deploy/deployment_progress"
require "jumpstart_deploy/deployer"
require "jumpstart_deploy/cli"

# Rails integration (conditional)
require "jumpstart_deploy/engine" if defined?(Rails)
