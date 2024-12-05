# frozen_string_literal: true

module JumpstartDeploy
  module Hatchbox
    class Client
      attr_reader :connection

      def initialize(connection = nil)
        @connection = connection || Connection.new
      end

      def create_application(name:, repository:, framework: "rails")
        response = connection.client.post(
          "#{Connection::API_URL}/apps",
          json: {
            app: {
              name: name,
              repository: repository,
              framework: framework
            }
          }
        )

        validate_response!(response)
        Application.new(JSON.parse(response.body.to_s))
      end

      def configure_environment(app_id, env_vars)
        response = connection.client.post(
          "#{Connection::API_URL}/apps/#{app_id}/env_vars",
          json: { env_vars: env_vars }
        )

        validate_response!(response)
        true
      end

      private

      def validate_response!(response)
        return true if response.status.success?

        error_message = begin
          JSON.parse(response.body.to_s)["error"]
        rescue JSON::ParserError
          "API request failed"
        end

        raise Error, error_message
      end
    end
  end
end
