# frozen_string_literal: true

Rails.application.routes.draw do
  get "dummy_rails7_testing/index"
  mount JumpstartDeploy::Engine => "/jumpstart_deploy"
end
