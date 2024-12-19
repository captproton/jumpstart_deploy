require "bundler/setup"
require "jumpstart_deploy"
require "thor"
require "tty-prompt"
require "webmock/rspec"
require "vcr"
require "tty-command"

# Load all support files
Dir[File.join(File.dirname(__FILE__), "support", "**", "*.rb")].each { |f| require f }

# Configure VCR
VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter sensitive data
  config.filter_sensitive_data("<GITHUB_TOKEN>") { ENV["GITHUB_TOKEN"] }
  config.filter_sensitive_data("<HATCHBOX_TOKEN>") { ENV["HATCHBOX_API_TOKEN"] }

  # Don't allow any real network connections
  config.allow_http_connections_when_no_cassette = false
end

# Configure WebMock
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Detailed output for single specs
  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  # Clean up test files after each example
  config.after(:each) do
    FileUtils.rm_rf(Dir["tmp/test_*"])
  end

  # Set up test environment variables
  config.before(:each) do
    ENV["GITHUB_TOKEN"] = "test_github_token"
    ENV["HATCHBOX_API_TOKEN"] = "test_hatchbox_token"
    ENV["JUMPSTART_REPO_URL"] = "git@github.com:test/jumpstart-pro.git"
  end
end
