# frozen_string_literal: true

require "spec_helper"

RSpec.describe JumpstartDeploy::Hatchbox::Application do
  let(:attributes) do
    {
      "id" => 1,
      "name" => "test-app",
      "status" => "deployed"
    }
  end

  subject(:application) { described_class.new(attributes) }

  it "maps API response attributes" do
    expect(application.id).to eq(1)
    expect(application.name).to eq("test-app")
    expect(application.status).to eq("deployed")
  end

  describe "#deployed?" do
    it "returns true when status is deployed" do
      expect(application).to be_deployed
    end

    it "returns false for other statuses" do
      application = described_class.new(attributes.merge("status" => "pending"))
      expect(application).not_to be_deployed
    end
  end
end
