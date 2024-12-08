# frozen_string_literal: true

require "faraday"
require "json"

module JumpstartDeploy
  module Hatchbox
    class Connection
      BASE_URL = "https://app.hatchbox.io/api/v1"

      def initialize(token = nil)
        @token = token || fetch_token
        setup_client
      end

      def request(method, path, params = {})
        response = client.public_send(method, path, params)
        parse_response(response)
      rescue Faraday::Error => e
        raise JumpstartDeploy::Error, "Network error: #{e.message}"
      end

      private

      attr_reader :token, :client

      def fetch_token
        ENV.fetch("HATCHBOX_API_TOKEN") do
          raise JumpstartDeploy::Error, "HATCHBOX_API_TOKEN not configured"
        end
      end

      def setup_client
        @client = Faraday.new(url: BASE_URL) do |f|
          f.request :json
          f.response :json
          f.headers["Authorization"] = "Bearer #{token}"
          f.adapter Faraday.default_adapter
        end
      end

      def parse_response(response)
        return response.body if response.success?

        error_message = response.body["error"] if response.body.is_a?(Hash)
        raise JumpstartDeploy::Error, "API error: #{error_message || response.reason_phrase}"
      end
    end
  end
end
