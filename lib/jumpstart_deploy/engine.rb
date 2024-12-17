# frozen_string_literal: true

module JumpstartDeploy
  if defined?(Rails)
    class Engine < ::Rails::Engine
      isolate_namespace JumpstartDeploy

      config.generators do |g|
        g.test_framework :rspec
        g.fixture_replacement :factory_bot
        g.factory_bot dir: "spec/factories"
      end

      # Include view helpers
      initializer "jumpstart_deploy.helpers" do
        ActiveSupport.on_load(:action_controller_base) do
          helper JumpstartDeploy::ComponentsHelper
        end
      end
    end
  end
end
