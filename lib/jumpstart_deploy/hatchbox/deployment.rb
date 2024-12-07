# frozen_string_literal: true

module JumpstartDeploy
  module Hatchbox
    class Deployment
      STATUS_POLLING_INTERVAL = 10 # seconds
      MAX_POLL_ATTEMPTS = 30      # 5 minutes total

      def initialize(client, app_id)
        @client = client
        @app_id = app_id 
        @status = nil
      end

      def trigger
        response = @client.post("apps/#{@app_id}/deployments")
        @deployment_id = response.fetch("id")
        track_status
      rescue KeyError => e
        raise DeploymentError, "Invalid deployment response: #{e.message}"
      rescue StandardError => e
        raise DeploymentError, "Deployment failed: #{e.message}"
      end

      private

      def track_status
        MAX_POLL_ATTEMPTS.times do
          status = fetch_status
          return status if deployment_completed?(status)
          sleep STATUS_POLLING_INTERVAL
        end
        raise DeploymentError, "Deployment timed out"
      end

      def fetch_status
        response = @client.get("apps/#{@app_id}/deployments/#{@deployment_id}")
        @status = response.fetch("status")
      rescue KeyError => e
        raise DeploymentError, "Invalid status response: #{e.message}"
      end

      def deployment_completed?(status)
        %w[completed failed].include?(status)
      end
    end
  end
end