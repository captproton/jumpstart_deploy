require_relative "lib/jumpstart_deploy/version"

Gem::Specification.new do |spec|
  spec.name        = "jumpstart_deploy"
  spec.version     = JumpstartDeploy::VERSION
  spec.authors     = [ "captproton" ]
  spec.email       = [ "carl@wdwhub.net" ]
  spec.homepage    = "https://github.com/captproton/jumpstart_deploy"
  spec.summary     = "A streamlined, repeatable process for deploying fresh Jumpstart Pro Rails apps to Hatchbox throughout your day."
  spec.description = "This tool will: Prompt for app name and any additional options
Create a GitHub repo
Set up Jumpstart Pro
Configure Hatchbox
Show you the URLs when done"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/captproton/jumpstart_deploy"
  spec.metadata["changelog_uri"] = "https://github.com/captproton/jumpstart_deploy/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end
  spec.test_files = Dir["spec/**/*"]

  # Core dependencies for CLI
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "tty-prompt", "~> 0.23"
  spec.add_dependency "tty-spinner", "~> 0.9.3"
  spec.add_dependency "tty-command", "~> 0.10.1"
  spec.add_dependency "octokit", "~> 9.2"
  spec.add_dependency "faraday", "~> 2.7"
  spec.add_dependency "faraday-retry"

  # Rails engine dependencies
  spec.add_dependency "rails", ">= 8.0.0"
  spec.add_dependency "jsbundling-rails"
  spec.add_dependency "stimulus-rails"
  spec.add_dependency "turbo-rails"
  spec.add_dependency "tailwindcss-rails"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "webmock", "~> 3.24"
  spec.add_development_dependency "vcr", "~> 6.3"
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "ffaker"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "pry-doc"
  spec.add_development_dependency "pry-rails"
  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "binding_of_caller"
end
