# frozen_string_literal: true

require_relative "lib/jumpstart_deploy/version"

Gem::Specification.new do |spec|
  spec.name = "jumpstart_deploy"
  spec.version = JumpstartDeploy::VERSION
  spec.authors = [ "Your Name" ]
  spec.email = [ "your@email.com" ]

  spec.summary = "CLI tool for deploying Jumpstart Pro apps to Hatchbox"
  spec.description = "Streamlines the process of creating and deploying new Jumpstart Pro applications to Hatchbox"
  spec.homepage = "https://github.com/captproton/jumpstart_deploy"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir["{lib,exe}/**/*", "README.md", "LICENSE.txt"]
  spec.bindir = "exe"
  spec.executables = [ "jumpstart-deploy" ]

  spec.add_dependency "thor", "~> 1.2"
  spec.add_dependency "octokit", "~> 9.0"
  spec.add_dependency "tty-prompt", "~> 0.23"
  spec.add_dependency "tty-spinner", "~> 0.9"
  spec.add_dependency "http", "~> 5.1"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "rubocop-rake", "~> 0.6"
  spec.add_development_dependency "rubocop-rspec", "~> 2.22"
end
