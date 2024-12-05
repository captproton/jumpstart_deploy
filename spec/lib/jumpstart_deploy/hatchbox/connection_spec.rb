# frozen_string_literal: true

require "spec_helper"
require "jumpstart_deploy/hatchbox/connection"

RSpec.describe JumpstartDeploy::Hatchbox::Connection do
  let(:access_token) { "fake_token" }
  let(:connection) { described_class.new(access_token) }

  describe "#initialize" do
    context "with access token" do
      it "accepts the token" do
        expect(connection.client.default_options[:headers]["Authorization"])
          .to eq(access_token)
      end
    end

    context "without access token" do
      before { ENV["HATCHBOX_API_TOKEN"] = nil }

      it "raises error when environment variable not set" do
        expect { described_class.new }.to raise_error(JumpstartDeploy::Hatchbox::Error)
      end

      it "uses environment variable when available" do
        ENV["HATCHBOX_API_TOKEN"] = "env_token"
        connection = described_class.new
        expect(connection.client.default_options[:headers]["Authorization"])
          .to eq("env_token")
      end
    end

    it "validates token presence" do
      expect { described_class.new("") }
        .to raise_error(JumpstartDeploy::Hatchbox::Error)
    end
  end
end