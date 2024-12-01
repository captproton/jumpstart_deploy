Rails.application.routes.draw do
  mount JumpstartDeploy::Engine => "/jumpstart_deploy"
end
