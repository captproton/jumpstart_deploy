# frozen_string_literal: true

require "spec_helper"

RSpec.describe JumpstartDeploy::Hatchbox::Client do
  let(:token) { "test_token" }
  let(:client) { described_class.new(token: token) }

  describe "#initialize" do
    it "accepts a token" do
      expect { client }.not_to raise_error
    end

    it "uses HATCHBOX_API_TOKEN environment variable" do
      ENV["HATCHBOX_API_TOKEN"] = "env_token"
      expect { described_class.new }.not_to raise_error
    end

    it "raises error when no token available" do
      ENV["HATCHBOX_API_TOKEN"] = nil
      expect { described_class.new }.to raise_error(JumpstartDeploy::Hatchbox::Error)
    end
  end

  describe "API requests", vcr: { cassette_name: "hatchbox_api" } do
    let(:app_id) { "123" }

    describe "#post" do
      let(:data) { { name: "test app" } }

      it "makes POST request with JSON data" do
        VCR.use_cassette("hatchbox/create_app") do
          response = client.post("apps", data)
          expect(response).to include("id")
        end
      end

      it "handles API errors" do
        VCR.use_cassette("hatchbox/create_app_error") do
          expect {
            client.post("apps", {})
          }.to raise_error(JumpstartDeploy::Hatchbox::Error)
        end
      end
    end

    describe "#get" do
      it "makes GET request" do
        VCR.use_cassette("hatchbox/get_app") do
          response = client.get("apps/#{app_id}")
          expect(response).to include("id" => app_id)
        end
      end

      it "handles API errors" do
        VCR.use_cassette("hatchbox/get_app_error") do
          expect {
            client.get("apps/invalid")
          }.to raise_error(JumpstartDeploy::Hatchbox::Error)
        end
      end
    end
  end
end
