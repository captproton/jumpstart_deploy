# frozen_string_literal: true

require "spec_helper"
require "jumpstart_deploy/hatchbox/connection"

RSpec.describe JumpstartDeploy::Hatchbox::Connection do
  let(:access_token) { "fake_token" }
  let(:connection) { described_class.new(access_token) }

  describe "#initialize" do
    context "with access token" do
      it "configures client with proper headers" do
        client = connection.client
        expect(client.headers["Authorization"]).to eq("Bearer fake_token")
        expect(client.headers["Content-Type"]).to eq("application/json")
        expect(client.headers["Accept"]).to eq("application/json")
      end
    end

    context "without access token" do
      before { ENV["HATCHBOX_API_TOKEN"] = nil }

      it "raises error when environment variable not set" do
        expect { described_class.new }.to raise_error(JumpstartDeploy::Hatchbox::Error)
      end

      it "uses environment variable when available" do
        ENV["HATCHBOX_API_TOKEN"] = "env_token"
        client = described_class.new.client
        expect(client.headers["Authorization"]).to eq("Bearer env_token")
      end
    end

    it "validates token presence" do
      expect { described_class.new("") }
        .to raise_error(JumpstartDeploy::Hatchbox::Error)
    end
  end

  describe "#client" do
    let(:client) { connection.client }

    it "configures request retries" do
      handlers = client.builder.handlers
      expect(handlers).to include(Faraday::Retry::Middleware)
    end

    it "configures JSON parsing" do
      handlers = client.builder.handlers
      expect(handlers).to include(Faraday::Response::Json)
    end

    it "configures timeouts" do
      expect(client.options.timeout).to eq(30)
      expect(client.options.open_timeout).to eq(5)
    end

    it "uses proper base URL" do
      expect(client.url_prefix.to_s).to eq("https://app.hatchbox.io/api/v1")
    end
  end
end
