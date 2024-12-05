# frozen_string_literal: true

require "spec_helper"
require "jumpstart_deploy/hatchbox/client"

RSpec.describe JumpstartDeploy::Hatchbox::Client do
  let(:connection) { instance_double(JumpstartDeploy::Hatchbox::Connection) }
  let(:http_client) { instance_double(HTTP::Client) }
  let(:client) { described_class.new(connection) }
  
  before do
    allow(connection).to receive(:client).and_return(http_client)
  end

  describe "#create_application" do
    let(:app_params) do
      {
        name: "test-app",
        repository: "org/test-app",
        framework: "rails"
      }
    end

    let(:response_body) do
      {
        "id" => 123,
        "name" => "test-app",
        "repository" => "org/test-app",
        "framework" => "rails"
      }.to_json
    end

    let(:response) do
      instance_double(
        HTTP::Response,
        status: double(success?: true),
        body: instance_double(String, to_s: response_body)
      )
    end

    before do
      allow(http_client).to receive(:post).and_return(response)
    end

    it "creates application with proper parameters" do
      expect(http_client).to receive(:post)
        .with(
          "#{JumpstartDeploy::Hatchbox::Connection::API_URL}/apps",
          json: { app: app_params }
        )
        .and_return(response)

      client.create_application(**app_params)
    end

    it "returns application instance" do
      result = client.create_application(**app_params)
      expect(result).to be_a(JumpstartDeploy::Hatchbox::Application)
      expect(result.name).to eq("test-app")
    end

    context "with API error" do
      let(:response) do
        instance_double(
          HTTP::Response,
          status: double(success?: false),
          body: instance_double(String, to_s: { error: "Invalid params" }.to_json)
        )
      end

      it "raises error with message" do
        expect {
          client.create_application(**app_params)
        }.to raise_error(JumpstartDeploy::Hatchbox::Error, "Invalid params")
      end
    end
  end

  describe "#configure_environment" do
    let(:app_id) { 123 }
    let(:env_vars) do
      {
        "RAILS_ENV" => "production",
        "RAILS_LOG_TO_STDOUT" => "true"
      }
    end

    let(:response) do
      instance_double(
        HTTP::Response,
        status: double(success?: true),
        body: instance_double(String, to_s: "")
      )
    end

    before do
      allow(http_client).to receive(:post).and_return(response)
    end

    it "configures environment variables" do
      expect(http_client).to receive(:post)
        .with(
          "#{JumpstartDeploy::Hatchbox::Connection::API_URL}/apps/#{app_id}/env_vars",
          json: { env_vars: env_vars }
        )
        .and_return(response)

      client.configure_environment(app_id, env_vars)
    end
  end
end