# frozen_string_literal: true

require_relative "lib/jumpstart_deploy/version"

Gem::Specification.new do |spec|
  spec.name        = "jumpstart_deploy"
  spec.version     = JumpstartDeploy::VERSION
  spec.authors     = ["Carl Tanner"]
  spec.email       = ["carl@wdwhub.net"]
  spec.summary     = "Deployment automation for Jumpstart Pro apps"
  spec.description = "Automates deployment of Jumpstart Pro applications to Hatchbox"
  spec.homepage    = "https://github.com/captproton/jumpstart_deploy"
  spec.license     = "MIT"

  spec.files         = Dir["lib/**/*", "exe/*", "MIT-LICENSE", "Rakefile", "README.md"]
  spec.bindir        = "exe"
  spec.executables   = ["jumpstart_deploy"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7.0"

  # Runtime dependencies
  spec.add_dependency "faraday", "~> 2.7"
  spec.add_dependency "faraday-retry", "~> 2.2"
  spec.add_dependency "thor", "~> 1.2"
  spec.add_dependency "tty-command", "~> 0.10.1"
  spec.add_dependency "tty-prompt", "~> 0.23.1"
  spec.add_dependency "tty-spinner", "~> 0.9.3"
  spec.add_dependency "octokit", "~> 9.0"

  # Development dependencies are handled in Gemfile
  # This prevents the version conflicts we were seeing

end
