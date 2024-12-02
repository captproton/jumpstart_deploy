module JumpstartDeploy
  if defined?(Rails)
    class Engine < ::Rails::Engine
      isolate_namespace JumpstartDeploy
      
      # Include view helpers
      initializer "jumpstart_deploy.helpers" do
        ActiveSupport.on_load(:action_controller_base) do
          helper JumpstartDeploy::ComponentsHelper
        end
      end
    end
  end
end