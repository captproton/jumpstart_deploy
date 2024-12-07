# frozen_string_literal: true

require "spec_helper"
require "tty-spinner"

RSpec.describe JumpstartDeploy::DeploymentProgress do
  let(:progress) { described_class.new }
  let(:spinner_multi) { instance_double(TTY::Spinner::Multi) }
  let(:spinner) { instance_double(TTY::Spinner) }
  let(:steps) { described_class::STEPS }

  before do
    allow(TTY::Spinner::Multi).to receive(:new).and_return(spinner_multi)
    allow(spinner_multi).to receive(:register).and_return(spinner)
    allow(spinner).to receive(:update)
    allow(spinner).to receive(:auto_spin)
    allow(spinner).to receive(:success)
    allow(spinner).to receive(:error)
  end

  describe "#initialize" do
    it "sets up spinners for all deployment steps" do
      steps.each do |step, message|
        expect(spinner_multi).to receive(:register).with(:"#{step}")
      end
      progress
    end
  end

  describe "#start_step" do
    it "starts spinner for valid step" do
      expect(spinner_multi).to receive(:[]).with(:github_setup).and_return(spinner)
      expect(spinner).to receive(:auto_spin)
      progress.start_step(:github_setup)
    end

    it "raises error for invalid step" do
      expect {
        progress.start_step(:invalid_step)
      }.to raise_error(ArgumentError, "Invalid step: invalid_step")
    end
  end

  describe "#complete_step" do
    it "marks step as complete" do
      expect(spinner_multi).to receive(:[]).with(:github_setup).and_return(spinner)
      expect(spinner).to receive(:success)
      progress.complete_step(:github_setup)
    end

    it "updates step status" do
      allow(spinner_multi).to receive(:[]).with(:github_setup).and_return(spinner)
      progress.complete_step(:github_setup)
      expect(progress.instance_variable_get(:@step_statuses)[:github_setup]).to eq(:complete)
    end
  end

  describe "#fail_step" do
    let(:error) { StandardError.new("Test error") }

    before do
      allow(spinner_multi).to receive(:[]).with(:github_setup).and_return(spinner)
      allow(progress).to receive(:puts)
    end

    it "marks step as failed" do
      expect(spinner).to receive(:error)
      progress.fail_step(:github_setup, error)
    end

    it "updates step status" do
      progress.fail_step(:github_setup, error)
      expect(progress.instance_variable_get(:@step_statuses)[:github_setup]).to eq(:failed)
    end

    it "displays error message" do
      expect(progress).to receive(:puts).with(/Error during creating GitHub repository/)
      progress.fail_step(:github_setup, error)
    end

    it "shows troubleshooting steps" do
      expect(progress).to receive(:puts).with(/Troubleshooting steps:/)
      progress.fail_step(:github_setup, error)
    end

    context "with different steps" do
      it "shows relevant troubleshooting for clone_template" do
        expect(progress).to receive(:puts).with(/Check network connectivity/)
        progress.fail_step(:clone_template, error)
      end

      it "shows relevant troubleshooting for hatchbox_setup" do
        expect(progress).to receive(:puts).with(/Verify Hatchbox API token/)
        progress.fail_step(:hatchbox_setup, error)
      end

      it "shows relevant troubleshooting for deploy" do
        expect(progress).to receive(:puts).with(/Check deployment logs/)
        progress.fail_step(:deploy, error)
      end
    end
  end

  describe "#summary" do
    before do
      allow(progress).to receive(:puts)
      allow(spinner_multi).to receive(:[]).and_return(spinner)
    end

    it "displays deployment summary" do
      expect(progress).to receive(:puts).with("\nDeployment Status:")
      progress.summary
    end

    it "shows success status for completed steps" do
      progress.complete_step(:github_setup)
      expect(progress).to receive(:puts).with(/✓ Creating GitHub repository/)
      progress.summary
    end

    it "shows failure status for failed steps" do
      progress.fail_step(:github_setup, StandardError.new)
      expect(progress).to receive(:puts).with(/✗ Creating GitHub repository/)
      progress.summary
    end
  end
end
