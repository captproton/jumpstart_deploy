# frozen_string_literal: true

module JumpstartDeploy
  module Hatchbox
    class Deployment
      attr_reader :id, :status, :log

      def initialize(attributes = {})
        @id = attributes["id"]
        @status = attributes["status"]
        @log = attributes["log"]
      end

      def completed?
        status == "completed"
      end

      def failed?
        status == "failed"
      end

      def in_progress?
        %w[pending running].include?(status)
      end
    end
  end
end
