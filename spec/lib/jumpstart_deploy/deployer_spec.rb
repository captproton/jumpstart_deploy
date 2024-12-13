# spec/lib/jumpstart_deploy/deployer_spec.rb
require "spec_helper"

RSpec.describe JumpstartDeploy::Deployer do
  let(:deployer) { described_class.new }
  let(:progress) { instance_double(JumpstartDeploy::DeploymentProgress) }
  let(:github_client) { instance_double(JumpstartDeploy::GitHub::Client) }
  let(:hatchbox_client) { instance_double(JumpstartDeploy::Hatchbox::Client) }
  let(:options) { { "name" => "test-app" } }

  before do
    allow(JumpstartDeploy::GitHub::Client).to receive(:new).and_return(github_client)
    allow(JumpstartDeploy::Hatchbox::Client).to receive(:new).and_return(hatchbox_client)
    allow(JumpstartDeploy::DeploymentProgress).to receive(:new).and_return(progress)

    # Progress tracking
    allow(progress).to receive(:start)
    allow(progress).to receive(:success) 
    allow(progress).to receive(:error)

    # Allow operations to succeed by default
    allow(github_client).to receive(:create_repository).and_return(double(full_name: "org/test-app"))
    allow(hatchbox_client).to receive(:create_application)
    allow(JumpstartDeploy::ShellCommands).to receive(:git)
  end

  describe "#deploy" do
    it "tracks progress of deployment steps" do
      expect(progress).to receive(:start).with(:github_setup)
      expect(progress).to receive(:success).with(:github_setup)
      
      expect(progress).to receive(:start).with(:app_setup)
      expect(progress).to receive(:success).with(:app_setup)

      deployer.deploy(options)
    end

    context "when GitHub setup fails" do
      before do
        allow(github_client).to receive(:create_repository)
          .and_raise(StandardError.new("API error"))
      end

      it "shows error and stops deployment" do
        expect(progress).to receive(:error).with(:github_setup, instance_of(StandardError))
        expect(progress).not_to receive(:start).with(:app_setup)

        expect { deployer.deploy(options) }.to raise_error(StandardError)
      end
    end
  end
end