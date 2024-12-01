# frozen_string_literal: true

module JumpstartDeploy
  class Engine < ::Rails::Engine
    isolate_namespace JumpstartDeploy

    # Include view helpers
    initializer "jumpstart_deploy.helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper JumpstartDeploy::ComponentsHelper
      end
    end

    config.generators do |g|
      g.test_framework :rspec, fixtures: false
      g.fixture_replacement :factory_bot, dir: "spec/factories"
      g.assets false
      g.helper false
    end
  end
end
