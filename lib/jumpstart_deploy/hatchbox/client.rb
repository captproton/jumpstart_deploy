# frozen_string_literal: true

require "faraday"
require "json"

module JumpstartDeploy
  module Hatchbox
    class Client
      BASE_PATH = "/api/v1"

      def initialize(connection: nil, progress: nil)
        @connection = connection
        @progress = progress
        @token = fetch_access_token
      end

      def create_application(params)
        with_progress(:hatchbox_setup) do
          response = connection.post("#{BASE_PATH}/apps", app: params)
          Application.new(JSON.parse(response.body))
        end
      end

      def configure_environment(app_id, env_vars)
        response = connection.post(
          "#{BASE_PATH}/apps/#{app_id}/env_vars",
          env_vars: env_vars
        )
        JSON.parse(response.body)
      rescue Faraday::Error => e
        raise Error, "Failed to configure environment: #{e.message}"
      end

      def deploy(app_id)
        with_progress(:deploy) do
          response = connection.post("#{BASE_PATH}/apps/#{app_id}/deploys")
          JSON.parse(response.body)
        end
      end

      def deployment_status(app_id, deploy_id)
        response = connection.get("#{BASE_PATH}/apps/#{app_id}/deploys/#{deploy_id}")
        JSON.parse(response.body)
      rescue Faraday::Error => e
        raise Error, "Failed to fetch deployment status: #{e.message}"
      end

      private

      def connection
        @connection ||= Faraday.new(url: "https://api.hatchbox.io") do |conn|
          conn.request :authorization, "Bearer", @token
          conn.request :json
          conn.response :json
          conn.adapter Faraday.default_adapter
        end
      end

      def fetch_access_token
        ENV.fetch("HATCHBOX_API_TOKEN") do
          raise Error, "HATCHBOX_API_TOKEN environment variable is not set"
        end
      end

      def with_progress(step)
        @progress&.start_step(step)
        result = yield
        @progress&.complete_step(step)
        result
      rescue Faraday::Error => e
        @progress&.fail_step(step, e)
        raise Error, "Failed during #{step}: #{e.message}"
      end
    end
  end
end