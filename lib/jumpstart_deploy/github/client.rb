# frozen_string_literal: true

require "octokit"

module JumpstartDeploy
  module GitHub
    class Client
      def initialize(connection = nil, progress: nil)
        if connection
          @connection = connection
        else
          @client = Octokit::Client.new(access_token: fetch_access_token)
        end
        @progress = progress
      end

      def create_repository(name, team: nil)
        @progress&.start_step(:github_setup)
        response = create_private_repository(name)

        repository = Repository.new(
          name: response.name,
          full_name: response.full_name,
          html_url: response.html_url,
          ssh_url: response.ssh_url
        )

        begin
          grant_team_access(repository.full_name, team) if team
          @progress&.complete_step(:github_setup)
        rescue Octokit::NotFound
          @progress&.fail_step(:github_setup, Error.new("Team not found"))
          raise Error, "Team not found"
        end

        repository
      rescue Octokit::UnprocessableEntity
        @progress&.fail_step(:github_setup, Error.new("Repository already exists"))
        raise Error, "Repository already exists"
      rescue Octokit::NotFound
        @progress&.fail_step(:github_setup, Error.new("Resource not found"))
        raise Error, "Resource not found"
      rescue Octokit::Error => e
        @progress&.fail_step(:github_setup, e)
        raise Error, "GitHub API error: #{e.message}"
      end

      private

      def create_private_repository(name)
        client.create_repository(
          name,
          private: true,
          auto_init: true,
          description: "Rails application using Jumpstart Pro"
        )
      end

      def grant_team_access(repo_name, team)
        client.add_team_repository(team, repo_name, permission: "push")
      end

      def client
        @client ||= @connection.client
      end

      def fetch_access_token
        ENV.fetch("GITHUB_TOKEN") do
          raise Error, "GITHUB_TOKEN environment variable is not set"
        end
      end
    end
  end
end
