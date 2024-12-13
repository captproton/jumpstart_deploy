# frozen_string_literal: true

module JumpstartDeploy
  if defined?(Rails)
    class Engine < ::Rails::Engine
      isolate_namespace JumpstartDeploy

<<<<<<< HEAD
    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: "spec/factories"
=======
      # Include view helpers
      initializer "jumpstart_deploy.helpers" do
        ActiveSupport.on_load(:action_controller_base) do
          helper JumpstartDeploy::ComponentsHelper
        end
      end
>>>>>>> 19c95f3624e2ee776253c19602f4f0d8b3df7eea
    end
  end
end