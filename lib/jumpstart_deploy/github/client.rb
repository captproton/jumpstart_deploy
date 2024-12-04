# frozen_string_literal: true

module JumpstartDeploy
  module GitHub
    class Client
      def initialize(connection)
        @connection = connection
      end

      def create_repository(name, team: nil)
        repo = create_private_repository(name)
        grant_team_access(repo.full_name, team) if team
        Repository.new(repo.to_h)
      rescue Octokit::Error => e
        handle_github_error(e)
      end

      private

      def create_private_repository(name)
        @connection.client.create_repository(
          name,
          private: true,
          description: "Rails application using Jumpstart Pro"
        )
      end

      def grant_team_access(repo_name, team)
        @connection.client.add_team_repository(team, repo_name, permission: "push")
      end

      def handle_github_error(error)
        case error
        when Octokit::UnprocessableEntity
          raise Error, "Repository already exists"
        when Octokit::NotFound
          raise Error, "Team not found"
        else
          raise Error, "GitHub API error: #{error.message}"
        end
      end
    end
  end
end