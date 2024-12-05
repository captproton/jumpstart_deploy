# frozen_string_literal: true

require "spec_helper"
require "jumpstart_deploy/hatchbox/client"

RSpec.describe JumpstartDeploy::Hatchbox::Client do
  let(:connection) { instance_double(JumpstartDeploy::Hatchbox::Connection) }
  let(:faraday_client) { instance_double(Faraday::Connection) }
  let(:client) { described_class.new(connection) }
  
  before do
    allow(connection).to receive(:client).and_return(faraday_client)
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
      }
    end

    let(:response) do
      instance_double(
        Faraday::Response,
        success?: true,
        body: response_body
      )
    end

    before do
      allow(faraday_client).to receive(:post).and_yield(
        instance_double(Faraday::Request).as_null_object
      ).and_return(response)
    end

    it "creates application with proper parameters" do
      expect(client.create_application(**app_params))
        .to be_a(JumpstartDeploy::Hatchbox::Application)
    end

    context "with API error" do
      let(:response) do
        instance_double(
          Faraday::Response,
          success?: false,
          body: { "error" => "Invalid params" }
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
      instance_double(Faraday::Response, success?: true, body: "")
    end

    before do
      allow(faraday_client).to receive(:post).and_yield(
        instance_double(Faraday::Request).as_null_object
      ).and_return(response)
    end

    it "configures environment variables" do
      expect(client.configure_environment(app_id, env_vars)).to be true
    end
  end
end