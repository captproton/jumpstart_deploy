require 'spec_helper'

RSpec.describe JumpstartDeploy::Deployer do
  let(:deployer) { described_class.new }
  let(:options) { { "name" => "test-app", "team" => "engineering" } }
  let(:github_client) { instance_double(Octokit::Client) }
  let(:repo_response) do 
    double(
      html_url: "https://github.com/org/test-app",
      ssh_url: "git@github.com:org/test-app.git",
      full_name: "org/test-app"
    )
  end

  before do
    allow(Octokit::Client).to receive(:new).and_return(github_client)
    allow(github_client).to receive(:create_repository).and_return(repo_response)
    
    # Stub shell commands
    allow(JumpstartDeploy::ShellCommands).to receive(:git)
    allow(JumpstartDeploy::ShellCommands).to receive(:bundle)
    allow(JumpstartDeploy::ShellCommands).to receive(:rails)
  end

  describe "#deploy" do
    before do
      # Stub HTTP client for Hatchbox API
      allow(HTTP).to receive(:auth).and_return(HTTP)
      allow(HTTP).to receive(:post).and_return(
        double(
          status: double(success?: true),
          body: double(to_s: { id: 123 }.to_json)
        )
      )
    end

    context "with valid options" do
      it "executes deployment steps in order" do
        expect(deployer).to receive(:create_github_repo).ordered
        expect(deployer).to receive(:clone_jumpstart).ordered
        expect(deployer).to receive(:configure_jumpstart).ordered
        expect(deployer).to receive(:setup_hatchbox).ordered
        expect(deployer).to receive(:display_results).ordered
        
        deployer.deploy(options)
      end
    end

    context "with GitHub errors" do
      it "handles repository creation failures" do
        allow(github_client).to receive(:create_repository)
          .and_raise(Octokit::Error.new)

        expect { deployer.deploy(options) }
          .to raise_error(JumpstartDeploy::CommandError)
      end

      it "handles repository conflicts" do
        allow(github_client).to receive(:create_repository)
          .and_raise(Octokit::Conflict)

        expect { deployer.deploy(options) }
          .to raise_error(JumpstartDeploy::CommandError, /Repository already exists/)
      end
    end

    context "with Hatchbox API errors" do
      it "handles API failures gracefully" do
        allow(HTTP).to receive(:post)
          .and_raise(HTTP::Error.new("API Error"))

        expect { deployer.deploy(options) }
          .to raise_error(JumpstartDeploy::CommandError, /Hatchbox configuration failed/)
      end
    end
  end

  describe "#create_github_repo" do
    it "creates private repository with correct parameters" do
      expect(github_client).to receive(:create_repository).with(
        "test-app",
        hash_including(
          private: true,
          description: "Rails application using Jumpstart Pro"
        )
      )

      deployer.send(:create_github_repo)
    end

    context "with team access" do
      before do
        allow(github_client).to receive(:add_team_repository)
      end

      it "adds team to repository when specified" do
        expect(github_client).to receive(:add_team_repository).with(
          "engineering",
          repo_response.full_name,
          permission: "push"
        )

        deployer.deploy(options)
      end
    end
  end

  describe "#setup_hatchbox" do
    let(:hatchbox_response) { double(status: double(success?: true), body: { id: 123 }.to_json) }

    before do
      allow(HTTP).to receive(:auth).and_return(HTTP)
      allow(HTTP).to receive(:post).and_return(hatchbox_response)
    end

    it "configures application with correct parameters" do
      expect(HTTP).to receive(:post).with(
        "https://app.hatchbox.io/api/v1/apps",
        json: {
          app: {
            name: "test-app",
            repository: repo_response.full_name,
            framework: "rails"
          }
        }
      )

      deployer.send(:setup_hatchbox)
    end

    it "sets up required environment variables" do
      expect(HTTP).to receive(:post).with(
        %r{/env_vars$},
        json: {
          env_vars: hash_including(
            "RAILS_ENV" => "production",
            "RAILS_LOG_TO_STDOUT" => "true",
            "RAILS_SERVE_STATIC_FILES" => "true"
          )
        }
      )

      deployer.send(:setup_hatchbox)
    end
  end
end