# frozen_string_literal: true

require "bundler/setup"
require "jumpstart_deploy"
require "webmock/rspec"
require "vcr"
require "pry-byebug"

# Configure VCR for recording HTTP interactions
VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter sensitive data
  config.filter_sensitive_data('<GITHUB_TOKEN>') { ENV['GITHUB_TOKEN'] }
  config.filter_sensitive_data('<HATCHBOX_TOKEN>') { ENV['HATCHBOX_API_TOKEN'] }
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Set up test environment variables
  config.before(:each) do
    ENV['GITHUB_TOKEN'] = 'test_github_token'
    ENV['HATCHBOX_API_TOKEN'] = 'test_hatchbox_token'
    ENV['JUMPSTART_REPO_URL'] = 'git@github.com:test/jumpstart-pro.git'
  end

  # Clean up test files after each example
  config.after(:each) do
    FileUtils.rm_rf(Dir["tmp/test_*"])
  end
end
