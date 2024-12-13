# frozen_string_literal: true

require "http"

module JumpstartDeploy
  module Hatchbox
    class Error < StandardError; end

    class Client
      HATCHBOX_API = "https://app.hatchbox.io/api/v1"

      def initialize
        @token = fetch_access_token
      end

      def create_application(name:, repository: nil, framework: nil, environment_variables: {})
        post("apps", json: {
          app: {
            name: name,
            repository: repository,
            framework: framework,
            environment_variables: environment_variables
          }.compact
        })
      end

      def post(path, params = {})
        response = client.post("#{HATCHBOX_API}/#{path}", params)
        validate_response!(response)
        JSON.parse(response.body.to_s)
      end

      private

      def client
        @client ||= HTTP.auth("Bearer #{@token}")
      end

      def validate_response!(response)
        unless response.status.success?
          raise Error, "Hatchbox API error: #{response.body}"
        end
      end

      def fetch_access_token
        ENV.fetch("HATCHBOX_API_TOKEN") do
          raise Error, "HATCHBOX_API_TOKEN environment variable is not set"
        end
      end
    end
  end
end