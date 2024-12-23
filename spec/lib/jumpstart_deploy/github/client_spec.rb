# spec/lib/jumpstart_deploy/github/client_spec.rb
require "spec_helper"
require "jumpstart_deploy/github/client"

RSpec.describe JumpstartDeploy::GitHub::Client do
  let(:connection) { instance_double(JumpstartDeploy::GitHub::Connection) }
  let(:octokit_client) { instance_double(Octokit::Client) }
  let(:client) { described_class.new(connection) }

  before do
    allow(connection).to receive(:client).and_return(octokit_client)
  end

  describe "#create_repository" do
    let(:repo_attributes) do
      {
        name: "test-app",
        full_name: "org/test-app",
        html_url: "https://github.com/org/test-app",
        ssh_url: "git@github.com:org/test-app.git"
      }
    end

    # Updated to use basic double instead of instance_double for response
    let(:octokit_response) do
      double(
        name: repo_attributes[:name],
        full_name: repo_attributes[:full_name],
        html_url: repo_attributes[:html_url],
        ssh_url: repo_attributes[:ssh_url]
      )
    end

    it "creates private repository" do
      expect(octokit_client).to receive(:create_repository)
        .with("test-app", hash_including(private: true))
        .and_return(octokit_response)

      repository = client.create_repository("test-app")
      expect(repository.name).to eq "test-app"
      expect(repository.full_name).to eq "org/test-app"
    end

    context "with team access" do
      it "grants team access" do
        expect(octokit_client).to receive(:create_repository)
          .with("test-app", hash_including(private: true))
          .and_return(octokit_response)

        expect(octokit_client).to receive(:add_team_repository)
          .with("engineering", "org/test-app", permission: "push")

        repository = client.create_repository("test-app", team: "engineering")
        expect(repository.full_name).to eq "org/test-app"
      end
    end

    context "with errors" do
      it "handles repository exists error" do
        allow(octokit_client).to receive(:create_repository)
          .and_raise(Octokit::UnprocessableEntity)

        expect { client.create_repository("test-app") }
          .to raise_error(JumpstartDeploy::GitHub::Error, /already exists/)
      end

      it "handles team not found error" do
        allow(octokit_client).to receive(:create_repository)
          .and_return(octokit_response)

        allow(octokit_client).to receive(:add_team_repository)
          .and_raise(Octokit::NotFound)

        expect { client.create_repository("test-app", team: "nonexistent") }
          .to raise_error(JumpstartDeploy::GitHub::Error, /Team not found/)
      end
    end
  end
end
