# frozen_string_literal: true

module JumpstartDeploy
  module Hatchbox
    class Client
      API_URL = "https://app.hatchbox.io/api/v1"

      attr_reader :connection

      def initialize(token: nil, connection: nil)
        @token = token || ENV["HATCHBOX_API_TOKEN"]
        raise ClientError, "HATCHBOX_API_TOKEN not set" if @token.nil? && connection.nil?
        @connection = connection || build_connection
      end

      def post(path, data = {})
        response = connection.post(path) do |req|
          req.headers["Content-Type"] = "application/json"
          req.body = data.to_json
        end
        parse_response(response)
      rescue Faraday::Error => e
        raise ClientError, "HTTP request failed: #{e.message}"
      end

      def get(path)
        response = connection.get(path)
        parse_response(response)
      rescue Faraday::Error => e
        raise ClientError, "HTTP request failed: #{e.message}"
      end

      def create_application(name:, repository:, framework: "rails")
        response = post("/apps", app: { name: name, repository: repository, framework: framework })
        Application.new(response)
      end

      def configure_environment(app_id, env_vars)
        post("/apps/#{app_id}/env_vars", env_vars: env_vars)
        true
      end

      private

      def build_connection
        Faraday.new(url: API_URL) do |f|
          f.request :authorization, "Bearer", @token
          f.request :retry, max: 2, interval: 0.05
          f.request :json
          f.response :json
          f.adapter Faraday.default_adapter
        end
      end

      def parse_response(response)
        return response.body if response.success?

        error_message = response.body["error"] || response.body["message"] || "Request failed"
        raise ClientError, error_message
      end
    end
  end
end
