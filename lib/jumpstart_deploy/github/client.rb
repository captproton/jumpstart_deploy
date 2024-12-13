# frozen_string_literal: true

require "octokit"

module JumpstartDeploy
  module GitHub
    class Error < StandardError; end

    class Client
      def initialize
        @client = Octokit::Client.new(access_token: fetch_access_token)
      end

      def create_repository(name:, private: true, description: nil)
        # Convert keyword args to positional args + options hash for Octokit
        @client.create_repository(
          name.to_s,
          private: private,
          description: description
        )
      end

      def add_team_to_repository(team_name, repository)
        return unless team_name
        @client.add_team_repository(team_name, repository, permission: "push")
      end

      private

      def fetch_access_token
        ENV.fetch("GITHUB_TOKEN") do
          raise Error, "GITHUB_TOKEN environment variable is not set"
        end
      end
    end
  end
end