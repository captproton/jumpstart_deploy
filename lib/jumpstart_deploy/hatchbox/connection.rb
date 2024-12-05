# frozen_string_literal: true

require "http"

module JumpstartDeploy
  module Hatchbox
    class Error < StandardError; end

    class Connection
      API_URL = "https://app.hatchbox.io/api/v1"

      def initialize(access_token = nil)
        @access_token = access_token || fetch_access_token
        validate_token!
      end

      def client
        @client ||= HTTP.auth(@access_token)
      end

      private

      def fetch_access_token
        ENV.fetch("HATCHBOX_API_TOKEN") do
          raise Error, "HATCHBOX_API_TOKEN environment variable is not set"
        end
      end

      def validate_token!
        raise Error, "Access token cannot be blank" if @access_token.to_s.strip.empty?
      end
    end
  end
end
