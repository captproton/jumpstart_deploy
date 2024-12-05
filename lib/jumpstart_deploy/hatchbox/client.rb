# frozen_string_literal: true

module JumpstartDeploy
  module Hatchbox
    class Client
      attr_reader :connection

      def initialize(connection = nil)
        @connection = connection || Connection.new
      end

      def create_application(name:, repository:, framework: "rails")
        response = connection.client.post do |req|
          req.url "/apps"
          req.body = {
            app: {
              name: name,
              repository: repository,
              framework: framework
            }
          }.to_json
        end

        validate_response!(response)
        Application.new(response.body)
      end

      def configure_environment(app_id, env_vars)
        response = connection.client.post do |req|
          req.url "/apps/#{app_id}/env_vars"
          req.body = { env_vars: env_vars }.to_json
        end

        validate_response!(response)
        true
      end

      private

      def validate_response!(response)
        return true if response.success?

        error_message = begin
          response.body["error"]
        rescue StandardError
          "API request failed"
        end

        raise Error, error_message
      end
    end
  end
end
