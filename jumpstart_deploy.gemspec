# frozen_string_literal: true

require_relative "lib/jumpstart_deploy/version"

Gem::Specification.new do |spec|
  spec.name        = "jumpstart_deploy"
  spec.version     = JumpstartDeploy::VERSION
  spec.authors     = [ "Your Name" ]
  spec.email       = [ "your.email@example.com" ]
  spec.homepage    = "https://github.com/captproton/jumpstart_deploy"
  spec.summary     = "Deploy Jumpstart Pro Rails apps to Hatchbox"
  spec.description = "A deployment tool for Jumpstart Pro Rails applications"
  spec.license     = "MIT"

  spec.files = Dir["lib/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  spec.bindir = "exe"
  spec.executables = [ "jumpstart_deploy" ]
  spec.require_paths = [ "lib" ]

  spec.required_ruby_version = ">= 2.7.0"

  spec.add_dependency "thor", "~> 1.2"
  spec.add_dependency "tty-command", "~> 0.10.1"
  spec.add_dependency "tty-prompt", "~> 0.23.1"
  spec.add_dependency "tty-spinner", "~> 0.9.3"
  spec.add_dependency "octokit", "~> 9.0"
  spec.add_dependency "faraday-retry", "~> 2.2"

  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "webmock", "~> 3.24"
  spec.add_development_dependency "vcr", "~> 6.3"
  spec.add_development_dependency "pry-byebug", "~> 3.10"
end
