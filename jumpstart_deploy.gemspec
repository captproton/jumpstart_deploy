require_relative "lib/jumpstart_deploy/version"

Gem::Specification.new do |spec|
  spec.name        = "jumpstart_deploy"
  spec.version     = JumpstartDeploy::VERSION
  spec.authors     = [ "Your Name" ]
  spec.email       = [ "your@email.com" ]
  spec.summary     = "Deployment automation for Jumpstart Pro apps"
  spec.description = "Automates deployment of Jumpstart Pro applications to Hatchbox"
  spec.homepage    = "https://github.com/yourusername/jumpstart_deploy"
  spec.license     = "MIT"

  spec.files = Dir.glob("{lib}/**/*")

  spec.required_ruby_version = ">= 2.7.0"

  spec.add_dependency "faraday", "~> 2.7"
  spec.add_dependency "faraday-retry"

  # Development dependencies are handled in Gemfile
  # This prevents the version conflicts we were seeing
end
