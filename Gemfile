source "https://rubygems.org"

ruby "3.2.2"

# Specify your gem's dependencies in jumpstart_deploy.gemspec
gemspec

gem "puma"
gem "sqlite3"
gem "propshaft"

# Frontend
gem "jsbundling-rails", "~> 1.3"
gem "stimulus-rails", "~> 1.3"
gem "turbo-rails", "~> 2.0"
gem "tailwindcss-rails", "~> 3.0"

group :development, :test do
  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-rake", "~> 0.6", require: false
  gem "rspec", "~> 3.0"
  # CLI tools for testing
  gem "thor", "~> 1.3.2"
  gem "tty-prompt", "~> 0.23"
  gem "tty-spinner", "~> 0.9"
  # API clients
  gem "octokit", "~> 9.2.0"
  gem "http", "~> 5.2.0"
end

# Start debugger with binding.b [https://github.com/ruby/debug]
# gem "debug", ">= 1.0.0"
