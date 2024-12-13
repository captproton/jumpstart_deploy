require "bundler/setup"
require "jumpstart_deploy"
require "thor"
require "tty-prompt"
require "webmock/rspec"
require "vcr"

# Load all support files
Dir[File.join(File.dirname(__FILE__), "support", "**", "*.rb")].each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
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