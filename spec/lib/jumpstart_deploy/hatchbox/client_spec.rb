# spec/lib/jumpstart_deploy/hatchbox/client_spec.rb
require "spec_helper"
require "jumpstart_deploy/hatchbox/client"

RSpec.describe JumpstartDeploy::Hatchbox::Client do
  let(:connection) { instance_double(Faraday::Connection) }
  let(:progress) { instance_double(JumpstartDeploy::DeploymentProgress) }
  let(:client) { described_class.new(connection: connection, progress: progress) }
  let(:base_path) { described_class::BASE_PATH }

  let(:app_params) { { name: "test-app", repository: "org/test-app", framework: "rails" } }
  let(:env_vars) do
    {
      "RAILS_ENV" => "production",
      "RAILS_LOG_TO_STDOUT" => "true",
      "RAILS_SERVE_STATIC_FILES" => "true"
    }
  end

  before do
    allow(progress).to receive(:start_step)
    allow(progress).to receive(:complete_step)
    allow(progress).to receive(:fail_step)
  end

  describe "#create_application" do
    let(:app_response) { { "id" => 123, "name" => "test-app" } }
    let(:response) { double(body: app_response.to_json) }

    before do
      allow(connection).to receive(:post)
        .with("#{base_path}/apps", app: app_params)
        .and_return(response)
    end

    it "creates application with proper config" do
      expect(connection).to receive(:post)
        .with("#{base_path}/apps", app: app_params)

      client.create_application(app_params)
    end

    it "returns application representation" do
      result = client.create_application(app_params)
      expect(result).to be_a(JumpstartDeploy::Hatchbox::Application)
      expect(result.id).to eq(123)
    end

    it "tracks progress" do
      expect(progress).to receive(:start_step).with(:hatchbox_setup)
      expect(progress).to receive(:complete_step).with(:hatchbox_setup)

      client.create_application(app_params)
    end

    context "with errors" do
      before do
        allow(connection).to receive(:post)
          .and_raise(Faraday::Error.new("API Error"))
      end

      it "handles API errors" do
        expect {
          client.create_application(app_params)
        }.to raise_error(JumpstartDeploy::Hatchbox::Error)
      end

      it "reports progress failure" do
        expect(progress).to receive(:fail_step)
          .with(:hatchbox_setup, instance_of(Faraday::Error))

        begin
          client.create_application(app_params)
        rescue JumpstartDeploy::Hatchbox::Error
          # Expected error
        end
      end
    end
  end

  describe "#configure_environment" do
    let(:app_id) { 123 }
    let(:response) { double(body: { status: "success" }.to_json) }

    before do
      allow(connection).to receive(:post)
        .with("#{base_path}/apps/#{app_id}/env_vars", env_vars: env_vars)
        .and_return(response)
    end

    it "configures environment variables" do
      expect(connection).to receive(:post)
        .with("#{base_path}/apps/#{app_id}/env_vars", env_vars: env_vars)

      client.configure_environment(app_id, env_vars)
    end

    context "with errors" do
      before do
        allow(connection).to receive(:post)
          .and_raise(Faraday::Error.new("Config Error"))
      end

      it "handles configuration errors" do
        expect {
          client.configure_environment(app_id, env_vars)
        }.to raise_error(JumpstartDeploy::Hatchbox::Error)
      end
    end
  end

  describe "#deploy" do
    let(:app_id) { 123 }
    let(:deploy_response) { { id: 456, status: "pending" } }
    let(:response) { double(body: deploy_response.to_json) }

    before do
      allow(connection).to receive(:post)
        .with("#{base_path}/apps/#{app_id}/deploys")
        .and_return(response)
    end

    it "triggers deployment" do
      expect(connection).to receive(:post)
        .with("#{base_path}/apps/#{app_id}/deploys")

      client.deploy(app_id)
    end

    it "tracks deployment progress" do
      expect(progress).to receive(:start_step).with(:deploy)
      expect(progress).to receive(:complete_step).with(:deploy)

      client.deploy(app_id)
    end

    context "with errors" do
      before do
        allow(connection).to receive(:post)
          .and_raise(Faraday::Error.new("Deploy Error"))
      end

      it "handles deployment errors" do
        expect {
          client.deploy(app_id)
        }.to raise_error(JumpstartDeploy::Hatchbox::Error)
      end

      it "reports progress failure" do
        expect(progress).to receive(:fail_step)
          .with(:deploy, instance_of(Faraday::Error))

        begin
          client.deploy(app_id)
        rescue JumpstartDeploy::Hatchbox::Error
          # Expected error
        end
      end
    end
  end

  describe "#deployment_status" do
    let(:app_id) { 123 }
    let(:deploy_id) { 456 }
    let(:status_response) do
      {
        id: deploy_id,
        status: "completed",
        log: "Deployment successful"
      }
    end
    let(:response) { double(body: status_response.to_json) }

    before do
      allow(connection).to receive(:get)
        .with("#{base_path}/apps/#{app_id}/deploys/#{deploy_id}")
        .and_return(response)
    end

    it "fetches deployment status" do
      expect(connection).to receive(:get)
        .with("#{base_path}/apps/#{app_id}/deploys/#{deploy_id}")

      client.deployment_status(app_id, deploy_id)
    end

    it "returns status details" do
      result = client.deployment_status(app_id, deploy_id)
      expect(result["status"]).to eq("completed")
    end
  end
end