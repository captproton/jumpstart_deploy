# frozen_string_literal: true

module JumpstartDeploy
  module Hatchbox
    class Error < JumpstartDeploy::Error; end
    class ConnectionError < Error; end
    class ClientError < Error; end
    class TokenError < Error; end
    class ValidationError < Error; end
  end
end
