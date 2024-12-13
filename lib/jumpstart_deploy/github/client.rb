# frozen_string_literal: true

<<<<<<< HEAD
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
=======
module JumpstartDeploy
  module GitHub
    class Client
      def initialize(connection)
        @connection = connection
      end

      def create_repository(name, team: nil)
        response = create_private_repository(name)

        repository = Repository.new(
          name: response.name,
          full_name: response.full_name,
          html_url: response.html_url,
          ssh_url: response.ssh_url
        )

        begin
          grant_team_access(repository.full_name, team) if team
        rescue Octokit::NotFound
          raise Error, "Team not found"
        end

        repository
      rescue Octokit::UnprocessableEntity
        raise Error, "Repository already exists"
      rescue Octokit::NotFound
        raise Error, "Resource not found"
      rescue Octokit::Error => e
        raise Error, "GitHub API error: #{e.message}"
>>>>>>> 19c95f3624e2ee776253c19602f4f0d8b3df7eea
      end

      private

<<<<<<< HEAD
      def fetch_access_token
        ENV.fetch("GITHUB_TOKEN") do
          raise Error, "GITHUB_TOKEN environment variable is not set"
        end
      end
    end
  end
end
=======
      def create_private_repository(name)
        @connection.client.create_repository(
          name,
          private: true,
          auto_init: true,
          description: "Rails application using Jumpstart Pro"
        )
      end

      def grant_team_access(repo_name, team)
        @connection.client.add_team_repository(team, repo_name, permission: "push")
      end
    end
  end
end
>>>>>>> 19c95f3624e2ee776253c19602f4f0d8b3df7eea
