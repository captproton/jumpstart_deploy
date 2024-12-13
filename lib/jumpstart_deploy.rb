require "jumpstart_deploy/version"
require "jumpstart_deploy/cli"
require "jumpstart_deploy/shell_commands"
require "jumpstart_deploy/github/client"
require "jumpstart_deploy/hatchbox/client"
require "jumpstart_deploy/deployer"

# Only load Rails engine if Rails is defined
require "jumpstart_deploy/engine" if defined?(Rails)

module JumpstartDeploy
  class Error < StandardError; end
  class CommandError < Error; end
end