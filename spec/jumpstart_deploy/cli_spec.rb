require 'spec_helper'

RSpec.describe JumpstartDeploy::CLI do
  let(:cli) { described_class.new }
  let(:deployer) { instance_double(JumpstartDeploy::Deployer) }
  let(:prompt) { instance_double(TTY::Prompt) }

  before do
    allow(JumpstartDeploy::Deployer).to receive(:new).and_return(deployer)
    allow(TTY::Prompt).to receive(:new).and_return(prompt)
    # Always set up the optional team prompt to return nil
    allow(prompt).to receive(:ask).with("GitHub team name (optional):").and_return(nil)
  end

  describe "#new" do
    context "with complete options" do
      let(:options) { { "name" => "test_app", "team" => "engineering" } }

      it "creates a new deployment with provided options" do
        expect(deployer).to receive(:deploy).with(options)
        cli.new(options)
      end
    end

    context "with missing options" do
      let(:options) { {} }

      before do
        allow(prompt).to receive(:ask).with("What's the name of your app?", required: true)
          .and_return("test_app")
        allow(prompt).to receive(:ask).with("GitHub team name (optional):")
          .and_return("engineering")
      end

      it "prompts for missing information" do
        expect(deployer).to receive(:deploy)
          .with({ "name" => "test_app", "team" => "engineering" })
        cli.new(options)
      end
    end

    context "with invalid input" do
      it "rejects invalid application names" do
        expect {
          cli.new({ "name" => "Invalid-App-Name" })
        }.to raise_error(ArgumentError, /must be 3-63 characters, lowercase alphanumeric and underscores only/)
      end

      it "accepts valid app names" do
        expect(deployer).to receive(:deploy).with({ "name" => "valid_app_name" })
        cli.new({ "name" => "valid_app_name" })
      end

      it "rejects invalid team names" do
        expect {
          cli.new({ "name" => "valid_app", "team" => "Invalid Team!" })
        }.to raise_error(ArgumentError, /must be lowercase alphanumeric and hyphens only/)
      end
    end
  end
end
