ENV["RAILS_ENV"] = "test"

require_relative "spec_helper"
require_relative "dummy/config/environment"

require "rspec/rails"
require "factory_bot_rails"

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
