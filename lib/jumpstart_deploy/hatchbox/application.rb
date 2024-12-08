# frozen_string_literal: true

module JumpstartDeploy
  module Hatchbox
    # Domain object representing a Hatchbox application
    # Maps raw API responses to a clean Ruby interface
    class Application
      attr_reader :id, :name, :status

      def initialize(attributes)
        @id = attributes.fetch("id")
        @name = attributes.fetch("name") 
        @status = attributes.fetch("status", "pending")
      end

      def deployed?
        status == "deployed"
      end
    end
  end
end