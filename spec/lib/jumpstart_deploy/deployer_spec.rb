# frozen_string_literal: true

require "spec_helper"

RSpec.describe JumpstartDeploy::Deployer do
  let(:deployer) { described_class.new }
  let(:progress) { instance_double(JumpstartDeploy::DeploymentProgress) }
  let(:github_client) { instance_double(JumpstartDeploy::GitHub::Client) }
  let(:hatchbox_client) { instance_double(JumpstartDeploy::Hatchbox::Client) }
  let(:options) { { "name" => "test-app" } }
  let(:repository) { double(full_name: "org/test-app") }
  let(:deployment) { double(id: 123, status: "success") }

  before do
    # Mock external services
    allow(JumpstartDeploy::GitHub::Client).to receive(:new).and_return(github_client)
    allow(JumpstartDeploy::Hatchbox::Client).to receive(:new).and_return(hatchbox_client)
    allow(JumpstartDeploy::DeploymentProgress).to receive(:new).and_return(progress)

    # Progress tracking setup
    allow(progress).to receive(:start_step)
    allow(progress).to receive(:complete_step)
    allow(progress).to receive(:fail_step)
    allow(progress).to receive(:summary)

    # Client operations setup
    allow(github_client).to receive(:create_repository).and_return(repository)
    allow(hatchbox_client).to receive(:create_application).and_return("id" => "123")
    allow(hatchbox_client).to receive(:configure_environment)
    allow(hatchbox_client).to receive(:deploy).and_return(deployment)

    # Mock filesystem operations
    allow(JumpstartDeploy::ShellCommands).to receive(:git)
    allow(JumpstartDeploy::ShellCommands).to receive(:bundle)
    allow(JumpstartDeploy::ShellCommands).to receive(:rails)
    allow(Dir).to receive(:chdir).and_yield # Important: Mock chdir to yield without actually changing dirs
  end

  describe "#deploy" do
    it "tracks progress of deployment steps" do
      expect(progress).to receive(:start_step).with(:github_setup)
      expect(progress).to receive(:complete_step).with(:github_setup)

      expect(progress).to receive(:start_step).with(:clone_template)
      expect(progress).to receive(:complete_step).with(:clone_template)

      expect(progress).to receive(:start_step).with(:configure_app)
      expect(progress).to receive(:complete_step).with(:configure_app)

      expect(progress).to receive(:start_step).with(:hatchbox_setup)
      expect(progress).to receive(:complete_step).with(:hatchbox_setup)

      expect(progress).to receive(:start_step).with(:deploy)
      expect(progress).to receive(:complete_step).with(:deploy)

      deployer.deploy(options)
    end

    context "when GitHub setup fails" do
      before do
        allow(github_client).to receive(:create_repository)
          .and_raise(StandardError.new("GitHub API error"))
      end

      it "shows error and stops deployment" do
        expect(progress).to receive(:start_step).with(:github_setup)
        expect(progress).to receive(:fail_step).with(:github_setup, instance_of(StandardError))
        expect(progress).to receive(:summary)

        expect { deployer.deploy(options) }.to raise_error(StandardError, /GitHub API error/)
      end

      it "does not continue with remaining steps" do
        allow(progress).to receive(:fail_step) # Allow fail_step to prevent exit
        allow(progress).to receive(:summary)
        expect(progress).not_to receive(:start_step).with(:clone_template)

        expect { deployer.deploy(options) }.to raise_error(StandardError)
      end
    end

    context "when template setup fails" do
      before do
        allow(JumpstartDeploy::ShellCommands).to receive(:git)
          .and_raise(JumpstartDeploy::ShellCommands::CommandError.new("Clone failed"))
      end

      it "handles error and shows progress" do
        expect(progress).to receive(:start_step).with(:github_setup)
        expect(progress).to receive(:complete_step).with(:github_setup)
        expect(progress).to receive(:start_step).with(:clone_template)
        expect(progress).to receive(:fail_step).with(:clone_template,
instance_of(JumpstartDeploy::ShellCommands::CommandError))
        expect(progress).to receive(:summary)

        expect { deployer.deploy(options) }.to raise_error(JumpstartDeploy::ShellCommands::CommandError)
      end
    end
  end
end
