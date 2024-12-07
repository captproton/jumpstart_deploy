# frozen_string_literal: true

require "faraday"
require "faraday/retry"

module JumpstartDeploy
  module Hatchbox
    class Connection
      API_URL = "https://app.hatchbox.io/api/v1"

      def initialize(access_token = nil)
        @access_token = access_token || fetch_access_token
        validate_token!
      end

      def client
        @client ||= Faraday.new(API_URL) do |f|
          # Retry failed requests
          f.request :retry, {
            max: 2,
            interval: 0.05,
            interval_randomness: 0.5,
            backoff_factor: 2,
            exceptions: [
              Faraday::ConnectionFailed,
              Faraday::TimeoutError
            ]
          }

          # Parse JSON responses
          f.response :json

          # Log requests in debug mode
          f.response :logger if ENV["DEBUG"]

          # Set timeouts
          f.options.timeout = 30      # Total request timeout
          f.options.open_timeout = 5  # Connection open timeout

          # Authentication and headers
          f.headers["Authorization"] = "Bearer #{@access_token}"
          f.headers["Content-Type"] = "application/json"
          f.headers["Accept"] = "application/json"

          # Use Net::HTTP adapter
          f.adapter :net_http
        end
      end

      private

      def fetch_access_token
        ENV.fetch("HATCHBOX_API_TOKEN") do
          raise JumpstartDeploy::Hatchbox::Error, "HATCHBOX_API_TOKEN environment variable is not set"
        end
      end

      def validate_token!
        raise JumpstartDeploy::Hatchbox::Error, "Access token cannot be blank" if @access_token.to_s.strip.empty?
      end
    end
  end
end
