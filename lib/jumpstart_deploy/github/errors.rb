# frozen_string_literal: true

module JumpstartDeploy
  module GitHub
    class Error < JumpstartDeploy::Error; end
    class ConnectionError < Error; end
    class ClientError < Error; end
    class ValidationError < Error; end
  end
end