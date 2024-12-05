# frozen_string_literal: true

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
      end

      private

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
