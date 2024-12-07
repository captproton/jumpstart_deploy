# frozen_string_literal: true

require "tty-command"
require "tty-prompt"
require "tty-spinner"
require "octokit"
require "faraday"
require "faraday/retry"

module JumpstartDeploy
  class Error < StandardError; end
  class CommandError < Error; end
end

require "jumpstart_deploy/version"
require "jumpstart_deploy/hatchbox/errors"
require "jumpstart_deploy/shell_commands"
require "jumpstart_deploy/hatchbox/application"  # Load before client
require "jumpstart_deploy/hatchbox/connection"   # Load before client
require "jumpstart_deploy/hatchbox/deployment"   # Load before client
require "jumpstart_deploy/hatchbox/client"
require "jumpstart_deploy/cli"
require "jumpstart_deploy/deployer"
require "jumpstart_deploy/deployment_progress"
