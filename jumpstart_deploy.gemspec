require_relative "lib/jumpstart_deploy/version"

Gem::Specification.new do |spec|
  spec.name        = "jumpstart_deploy"
  spec.version     = JumpstartDeploy::VERSION
  spec.authors     = ["Your Name"]
  spec.email       = ["your.email@example.com"]
  spec.homepage    = "https://github.com/captproton/jumpstart_deploy"
  spec.summary     = "Deploy Jumpstart Pro Rails apps to Hatchbox"
  spec.description = "A deployment tool for Jumpstart Pro Rails applications"
  spec.license     = "MIT"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 7.0.0"
  spec.add_dependency "thor"
  spec.add_dependency "tty-command"
  spec.add_dependency "tty-prompt"
  spec.add_dependency "tty-spinner"
  spec.add_dependency "octokit"
  spec.add_dependency "faraday-retry"
  
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "pry-byebug"
end