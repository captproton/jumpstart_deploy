Rails.application.routes.draw do
  mount JumpstartDeploy::Engine => "/jumpstart_deploy"

  get "dummy_rails7_testing/index"
end
