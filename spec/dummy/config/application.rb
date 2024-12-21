require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile
Bundler.require(*Rails.groups)

# Explicitly require the engine
require "jumpstart_deploy"
require "jumpstart_deploy/engine"

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    # For Rails engine testing
    config.eager_load = false
    config.active_support.deprecation = :log
    config.active_support.test_order = :random
    config.secret_key_base = "abcdef0123456789"
  end
end
