# frozen_string_literal: true

module JumpstartDeploy
  module Hatchbox
    class Error < JumpstartDeploy::Error; end
    class ClientError < Error; end
    class DeploymentError < Error; end
  end
end
