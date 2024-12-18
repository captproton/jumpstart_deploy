Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.
  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local = true
  config.public_file_server.enabled = true
  config.cache_store = :null_store

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = :none

  # Tell Active Support which deprecation messages to disallow
  config.active_support.deprecation = :raise

  # Use SQL instead of Active Record's schema dumper when creating the test database
  config.active_record.schema_format = :sql

  # Raise exceptions for disallowed deprecations
  config.active_support.disallowed_deprecation = :raise

  # Print deprecation notices to the stderr
  config.active_support.disallowed_deprecation_warnings = []

  # Debug mode disables concatenation and preprocessing of assets
  config.assets.debug = true

  # Suppress logger output for asset requests
  config.assets.quiet = true

  # Raises error for missing translations
  config.i18n.raise_on_missing_translations = true
end
