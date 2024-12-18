source "https://rubygems.org"

ruby "3.2.2"

# Specify your gem's dependencies in jumpstart_deploy.gemspec
gemspec

gem "puma"
gem "sqlite3"
gem "propshaft"
gem "psych", "~> 5.2.1"

# Frontend
gem "jsbundling-rails", "~> 1.3"
gem "stimulus-rails", "~> 1.3"
gem "turbo-rails", "~> 2.0"
gem "tailwindcss-rails", "~> 3.0"

group :development, :test do
  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", "~> 1.0", require: false
  gem "rubocop-rake", "~> 0.6", require: false
  gem "rspec", "~> 3.13"
  # CLI tools for testing
  gem "thor", "~> 1.3"
  gem "tty-prompt", "~> 0.23"
  gem "tty-spinner", "~> 0.9.3"
  # API clients
  gem "octokit", "~> 9.2"
  gem "http", "~> 5.2"
  gem "faraday", "~> 2.7"
  gem "faraday-retry"
  gem "rspec-rails", "~> 7.1"
  gem "factory_bot_rails", "~> 6.4"
  gem "webmock", "~> 3.24"
  gem "vcr", "~> 6.3"
  gem "pry-byebug", "~> 3.10"
  # Additional development tools
  gem "ffaker"
  gem "guard-rspec"
  gem "pry-doc"
  gem "pry-rails"
  gem "awesome_print"
  gem "binding_of_caller"
end

# Start debugger with binding.b [https://github.com/ruby/debug]
# gem "debug", ">= 1.0.0"

# custom gems for this project
gem "tty-command", "~> 0.10.1"
# DO NOT WRITE BELOW THIS LINE. KEEP THINGS TIDY!
