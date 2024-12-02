require File.expand_path("../dummy/config/environment.rb", __FILE__)

require 'rspec/rails'
require 'factory_bot_rails'
require 'webmock/rspec'
require 'vcr'

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
  # rspec-expectations config
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Inherit metadata
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Detailed output for single specs
  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  # Random order execution
  config.order = :random
  Kernel.srand config.seed

  # Factory Bot configuration
  config.include FactoryBot::Syntax::Methods
  config.include JumpstartDeploy::Engine.routes.url_helpers

  # Clean up test files after each example
  config.after(:each) do
    FileUtils.rm_rf(Dir["tmp/test_*"])
  end

  # Set up test environment variables
  config.before(:each) do
    ENV['GITHUB_TOKEN'] = 'test_github_token'
    ENV['HATCHBOX_API_TOKEN'] = 'test_hatchbox_token'
    ENV['JUMPSTART_REPO_URL'] = 'git@github.com:test/jumpstart-pro.git'
  end
end
