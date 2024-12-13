# frozen_string_literal: true

<<<<<<< HEAD
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
=======
module JumpstartDeploy
  module Hatchbox
    class Client
      def initialize(connection:, progress:)
        @connection = connection
        @progress = progress
      end

      def create_application(params)
        @progress.start_step(:hatchbox_setup)
        response = @connection.post("/apps", app: params)
        application = Application.new(response)
        @progress.complete_step(:hatchbox_setup)
        application
      rescue Error => e
        @progress.fail_step(:hatchbox_setup, e)
        raise
      end

      def configure_environment(app_id, env_vars)
        @connection.post("/apps/#{app_id}/env_vars", env_vars: env_vars)
      end

      def deploy(app_id)
        @progress.start_step(:deploy)
        response = @connection.post("/apps/#{app_id}/deploys")
        @progress.complete_step(:deploy)
        response
      rescue Error => e
        @progress.fail_step(:deploy, e)
        raise
      end

      def deployment_status(app_id, deploy_id)
        @connection.get("/apps/#{app_id}/deploys/#{deploy_id}")
>>>>>>> 19c95f3624e2ee776253c19602f4f0d8b3df7eea
      end

      private

<<<<<<< HEAD
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
=======
      attr_reader :connection, :progress
    end
  end
end
>>>>>>> 19c95f3624e2ee776253c19602f4f0d8b3df7eea
