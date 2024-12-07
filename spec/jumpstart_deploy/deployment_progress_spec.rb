# frozen_string_literal: true

require "spec_helper"
require "tty-spinner"
require "jumpstart_deploy/deployment_progress"  # Ensure the class is required

RSpec.describe JumpstartDeploy::DeploymentProgress do
  let(:progress) { described_class.new }
  let(:spinner_multi) { double("TTY::Spinner::Multi") }  # Changed to a regular double
  let(:spinner) { double("TTY::Spinner") }
  let(:steps) { described_class::STEPS }

  before do
    allow(TTY::Spinner::Multi).to receive(:new).and_return(spinner_multi)
    allow(spinner_multi).to receive(:register).and_yield(spinner)  # Yield the spinner when registering
    allow(spinner_multi).to receive(:[]).and_return(spinner)        # Mock the [] method
    allow(spinner).to receive(:update)
    allow(spinner).to receive(:auto_spin)
    allow(spinner).to receive(:success)
    allow(spinner).to receive(:error)
  end

  describe "#initialize" do
    it "sets up spinners for all deployment steps" do
      steps.each do |step, message|
        expect(spinner_multi).to receive(:register).with(:"#{step}").and_yield(spinner)
        expect(spinner).to receive(:update).with(title: message)
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
      allow(spinner_multi).to receive(:[]).with(:github_setup).and_return(spinner)
      expect(spinner).to receive(:success)
      progress.complete_step(:github_setup)
      expect(progress.step_statuses[:github_setup]).to eq(:complete)
    end

    it "updates step status" do
      allow(spinner_multi).to receive(:[]).with(:github_setup).and_return(spinner)
      progress.complete_step(:github_setup)
      expect(progress.step_statuses[:github_setup]).to eq(:complete)
    end
  end

  describe "#fail_step" do
    it "marks step as failed" do
      allow(spinner_multi).to receive(:[]).with(:github_setup).and_return(spinner)
      expect(spinner).to receive(:error)
      expect {
        progress.fail_step(:github_setup, StandardError.new("Test Error"))
      }.to output(/Error during creating github repository:/).to_stdout
       .and raise_error(SystemExit)
      expect(progress.step_statuses[:github_setup]).to eq(:failed)
    end

    it "updates step status" do
      allow(spinner_multi).to receive(:[]).with(:github_setup).and_return(spinner)
      progress.fail_step(:github_setup, StandardError.new("Test Error"))
      expect(progress.step_statuses[:github_setup]).to eq(:failed)
    end

    it "displays error message" do
      allow(spinner_multi).to receive(:[]).with(:github_setup).and_return(spinner)
      expect {
 progress.fail_step(:github_setup,
StandardError.new("Test Error")) }.to output(/Error during creating github repository:/).to_stdout
    end

    it "shows troubleshooting steps" do
      allow(spinner_multi).to receive(:[]).with(:github_setup).and_return(spinner)
      expect {
 progress.fail_step(:github_setup, StandardError.new("Test Error")) }.to output(/Troubleshooting steps:/).to_stdout
    end

    context "with different steps" do
      it "shows relevant troubleshooting for clone_template" do
        allow(spinner_multi).to receive(:[]).with(:clone_template).and_return(spinner)
        expect {
 progress.fail_step(:clone_template, StandardError.new("Clone Error")) }.to output(/Troubleshooting steps:/).to_stdout
      end

      it "shows relevant troubleshooting for hatchbox_setup" do
        allow(spinner_multi).to receive(:[]).with(:hatchbox_setup).and_return(spinner)
        expect {
 progress.fail_step(:hatchbox_setup,
StandardError.new("Hatchbox Error")) }.to output(/Troubleshooting steps:/).to_stdout
      end

      it "shows relevant troubleshooting for deploy" do
        allow(spinner_multi).to receive(:[]).with(:deploy).and_return(spinner)
        expect {
 progress.fail_step(:deploy, StandardError.new("Deploy Error")) }.to output(/Troubleshooting steps:/).to_stdout
      end
    end
  end

  describe "#summary" do
    it "displays deployment summary" do
      allow(spinner_multi).to receive(:[]).with(:github_setup).and_return(spinner)
      allow(spinner).to receive(:success)
      progress.start_step(:github_setup)
      progress.complete_step(:github_setup)
      expect { progress.summary }.to output(/Deployment Status:/).to_stdout
    end

    it "shows success status for completed steps" do
      allow(spinner_multi).to receive(:[]).with(:github_setup).and_return(spinner)
      allow(spinner).to receive(:success)
      progress.start_step(:github_setup)
      progress.complete_step(:github_setup)
      expect { progress.summary }.to output(/✓ Creating GitHub repository/).to_stdout
    end

    it "shows failure status for failed steps" do
      allow(spinner_multi).to receive(:[]).with(:github_setup).and_return(spinner)
      allow(spinner).to receive(:error)
      progress.start_step(:github_setup)
      progress.fail_step(:github_setup, StandardError.new("Test Error"))
      expect { progress.summary }.to output(/✗ Creating GitHub repository/).to_stdout
    end
  end
end
