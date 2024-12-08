# frozen_string_literal: true

require "spec_helper"

RSpec.describe JumpstartDeploy::Hatchbox::Connection do
  let(:token) { "test_token" }
  let(:connection) { described_class.new(token) }

  describe "#initialize" do
    it "accepts an API token" do
      expect(connection.send(:client).headers["Authorization"]).to eq("Bearer #{token}")
    end

    context "without token" do
      before { ENV["HATCHBOX_API_TOKEN"] = nil }

      it "raises error when token not configured" do
        expect { described_class.new }.to raise_error(JumpstartDeploy::Hatchbox::Error)
      end

      it "uses HATCHBOX_API_TOKEN environment variable" do
        ENV["HATCHBOX_API_TOKEN"] = "env_token"
        connection = described_class.new
        expect(connection.send(:client).headers["Authorization"]).to eq("Bearer env_token")
      end
    end
  end

  describe "#request" do
    context "with successful response" do
      let(:response_data) { { "id" => 1, "name" => "test-app" } }

      before do
        stub_request(:get, "#{described_class::BASE_URL}/apps/1")
          .with(headers: { "Authorization" => "Bearer #{token}" })
          .to_return(status: 200, body: response_data.to_json)
      end

      it "returns parsed response data" do
        expect(connection.request(:get, "apps/1")).to eq(response_data)
      end
    end

    context "with error response" do
      before do
        stub_request(:get, "#{described_class::BASE_URL}/apps/1")
          .to_return(status: 422, body: { error: "Not found" }.to_json)
      end

      it "raises error with message" do
        expect { connection.request(:get, "apps/1") }
          .to raise_error(JumpstartDeploy::Hatchbox::Error, /Not found/)
      end
    end

    context "with network error" do
      before do
        stub_request(:get, "#{described_class::BASE_URL}/apps/1")
          .to_raise(Faraday::ConnectionFailed.new("Failed to connect"))
      end

      it "raises error with message" do
        expect { connection.request(:get, "apps/1") }
          .to raise_error(JumpstartDeploy::Hatchbox::Error, /Failed to connect/)
      end
    end
  end
end