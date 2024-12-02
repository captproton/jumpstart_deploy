require "jumpstart_deploy/version"
require "jumpstart_deploy/shell_commands"
require "jumpstart_deploy/cli"
require "jumpstart_deploy/deployer"

require "tty-command"
require "tty-prompt"
require "tty-spinner"
require "octokit"

# Only load the Rails engine if Rails is defined
require "jumpstart_deploy/engine" if defined?(Rails)

module JumpstartDeploy
  class Error < StandardError; end
  class CommandError < Error; end
end
