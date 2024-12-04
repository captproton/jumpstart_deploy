# spec/lib/jumpstart_deploy/github/connection_spec.rb
require "spec_helper"
require "jumpstart_deploy/github/connection"

RSpec.describe JumpstartDeploy::GitHub::Connection do
  let(:access_token) { "fake_token" }
  let(:connection) { described_class.new(access_token) }

  describe "#initialize" do
    it "accepts an access token" do
      expect(connection.send(:client_options)[:access_token]).to eq access_token
    end

    context "without access token" do
      it "raises error when GITHUB_TOKEN not set" do
        ENV["GITHUB_TOKEN"] = nil
        expect { described_class.new }.to raise_error(described_class::Error)
      end

      it "uses GITHUB_TOKEN environment variable" do
        ENV["GITHUB_TOKEN"] = "env_token"
        connection = described_class.new
        expect(connection.send(:client_options)[:access_token]).to eq "env_token"
      end
    end
  end
end