# frozen_string_literal: true

require "spec_helper"
require "jumpstart_deploy/hatchbox/application"

RSpec.describe JumpstartDeploy::Hatchbox::Application do
  let(:attributes) do
    {
      "id" => 123,
      "name" => "test-app",
      "repository" => "org/test-app",
      "framework" => "rails"
    }
  end

  subject(:application) { described_class.new(attributes) }

  it "initializes with attributes" do
    expect(application.id).to eq(123)
    expect(application.name).to eq("test-app")
    expect(application.repository).to eq("org/test-app")
    expect(application.framework).to eq("rails")
  end
end