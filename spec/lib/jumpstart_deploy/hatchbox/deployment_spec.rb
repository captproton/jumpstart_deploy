# frozen_string_literal: true

require "spec_helper"
require "jumpstart_deploy/hatchbox/deployment"

module JumpstartDeploy
  module Hatchbox
    RSpec.describe Deployment do
      let(:client) { instance_double(Client) }
      let(:app_id) { "123" }
      let(:deployment_id) { "456" }
      let(:deployment) { described_class.new(client, app_id) }

      describe "#trigger" do
        context "when successful" do
          before do
            allow(client).to receive(:post)
              .with("apps/#{app_id}/deployments")
              .and_return({ "id" => deployment_id })

            allow(client).to receive(:get)
              .with("apps/#{app_id}/deployments/#{deployment_id}")
              .and_return({ "status" => "completed" })
          end

          it "triggers deployment and tracks status" do
            expect(deployment.trigger).to eq "completed"
          end
        end

        context "when deployment fails" do
          before do
            allow(client).to receive(:post)
              .with("apps/#{app_id}/deployments")
              .and_return({ "id" => deployment_id })

            allow(client).to receive(:get)
              .with("apps/#{app_id}/deployments/#{deployment_id}")
              .and_return({ "status" => "failed" })
          end

          it "returns failed status" do
            expect(deployment.trigger).to eq "failed"
          end
        end

        context "when API returns invalid response" do
          before do
            allow(client).to receive(:post)
              .with("apps/#{app_id}/deployments")
              .and_return({})
          end

          it "raises DeploymentError" do
            expect { deployment.trigger }.to raise_error(
              DeploymentError,
              /Invalid deployment response/
            )
          end
        end

        context "when API request fails" do
          before do
            allow(client).to receive(:post)
              .and_raise(StandardError, "API error")
          end

          it "raises DeploymentError" do
            expect { deployment.trigger }.to raise_error(
              DeploymentError,
              /Deployment failed: API error/
            )
          end
        end
      end
    end
  end
end
