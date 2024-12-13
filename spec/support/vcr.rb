# frozen_string_literal: true

require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Ignore localhost requests (for test Rails server)
  config.ignore_localhost = true

  # Filter sensitive data
  config.filter_sensitive_data("<GITHUB_TOKEN>") { ENV["GITHUB_TOKEN"] }
  config.filter_sensitive_data("<HATCHBOX_TOKEN>") { ENV["HATCHBOX_API_TOKEN"] }
  
  # Allow all requests when no cassette
  config.allow_http_connections_when_no_cassette = true
end