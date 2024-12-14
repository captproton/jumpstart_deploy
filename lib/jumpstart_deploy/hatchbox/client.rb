# frozen_string_literal: true

require "http"

module JumpstartDeploy
  module Hatchbox
    class Client
      HATCHBOX_API = "https://app.hatchbox.io/api/v1"

      def initialize(progress: nil)
        @token = fetch_access_token
        @progress = progress
      end

      def create_application(name:, repository: nil, framework: nil, environment_variables: {})
        @progress&.start_step(:hatchbox_setup)
        response = post("apps", json: {
          app: {
            name: name,
            repository: repository,
            framework: framework,
            environment_variables: environment_variables
          }.compact
        })
        application = Application.new(response)
        @progress&.complete_step(:hatchbox_setup)
        application
      rescue Error => e
        @progress&.fail_step(:hatchbox_setup, e)
        raise
      end

      def configure_environment(app_id, env_vars)
        post("/apps/#{app_id}/env_vars", json: { env_vars: env_vars })
      end

      def deploy(app_id)
        @progress&.start_step(:deploy)
        response = post("/apps/#{app_id}/deploys")
        @progress&.complete_step(:deploy)
        response
      rescue Error => e
        @progress&.fail_step(:deploy, e)
        raise
      end

      def deployment_status(app_id, deploy_id)
        get("/apps/#{app_id}/deploys/#{deploy_id}")
      end

      private

      def post(path, params = {})
        response = client.post("#{HATCHBOX_API}/#{path}", params)
        validate_response!(response)
        JSON.parse(response.body.to_s)
      end

      def get(path)
        response = client.get("#{HATCHBOX_API}/#{path}")
        validate_response!(response)
        JSON.parse(response.body.to_s)
      end

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
          raise TokenError, "HATCHBOX_API_TOKEN environment variable is not set"
        end
      end

      attr_reader :token, :progress
    end
  end
end