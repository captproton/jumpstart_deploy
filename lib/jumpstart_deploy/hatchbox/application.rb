# frozen_string_literal: true

module JumpstartDeploy
  module Hatchbox
    class Application
      attr_reader :id, :name, :repository, :framework, :status

      def initialize(attributes = {})
        @id = attributes["id"]
        @name = attributes["name"]
        @repository = attributes["repository"]
        @framework = attributes["framework"]
        @status = attributes["status"]
      end

      def deployed?
        status == "deployed"
      end
    end
  end
end
