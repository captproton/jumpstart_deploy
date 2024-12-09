# lib/jumpstart_deploy/hatchbox/client.rb
# frozen_string_literal: true

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
      end

      private

      attr_reader :connection, :progress
    end
  end
end