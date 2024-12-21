# frozen_string_literal: true

require "spec_helper"

RSpec.describe JumpstartDeploy::DeploymentProgress do
  let(:spinner_multi) { instance_double(TTY::Spinner::Multi) }
  let(:registered_spinners) { {} }
  let(:orig_stdout) { $stdout }
  let(:stdout) { StringIO.new }

  before do
    $stdout = stdout
    allow(TTY::Spinner::Multi).to receive(:new).and_return(spinner_multi)

    described_class::STEPS.each do |step, message|
      spinner = instance_double(TTY::Spinner)
      allow(spinner).to receive(:auto_spin)
      allow(spinner).to receive(:success)
      allow(spinner).to receive(:error)
      allow(spinner).to receive(:update)

      registered_spinners[step] = spinner

      # Match implementation's string registration
      allow(spinner_multi).to receive(:register)
        .with(step.to_s)
        .and_return(spinner)
    end
  end

  after do
    $stdout = orig_stdout
  end

  describe "#start_step" do
    let(:progress) { described_class.new }

    it "starts spinner for valid step" do
      expect(registered_spinners[:github_setup]).to receive(:auto_spin)
      progress.start_step(:github_setup)
    end

    it "raises error for invalid step" do
      expect {
        progress.start_step(:invalid_step)
      }.to raise_error(ArgumentError, "Invalid step: invalid_step")
    end
  end

  describe "#complete_step" do
    let(:progress) { described_class.new }

    it "marks step as complete" do
      expect(registered_spinners[:github_setup]).to receive(:success)
      progress.complete_step(:github_setup)
    end

    it "updates step status" do
      expect {
        progress.complete_step(:github_setup)
      }.to change { progress.step_statuses[:github_setup] }.to(:complete)
    end
  end

  describe "#fail_step" do
    let(:error) { StandardError.new("Test error") }
    let(:progress) { described_class.new }

    it "marks step as failed" do
      expect(registered_spinners[:github_setup]).to receive(:error)
      progress.fail_step(:github_setup, error)
    end

    it "updates step status" do
      expect {
        progress.fail_step(:github_setup, error)
      }.to change { progress.step_statuses[:github_setup] }.to(:failed)
    end

    it "displays error message" do
      progress.fail_step(:github_setup, error)
      expect(stdout.string).to include("Error during #{described_class::STEPS[:github_setup]}")
    end

    it "shows troubleshooting steps" do
      expect {
        progress.fail_step(:github_setup, error)
      }.to output(/Troubleshooting steps:/).to_stdout
    end

    context "with different steps" do
      described_class::STEPS.keys.each do |step|
        it "shows relevant troubleshooting for #{step}" do
          progress.fail_step(step, error)
          output = stdout.string
          expect(output).to include("Error during #{described_class::STEPS[step]}")
        end
      end
    end
  end

  describe "#interrupt_step" do
    let(:progress) { described_class.new }

    it "handles step interruption" do
      expect(registered_spinners[:github_setup]).to receive(:error).with("Interrupted")
      expect {
        progress.interrupt_step(:github_setup, "User cancelled")
      }.to output(/Deployment interrupted: User cancelled/).to_stdout
    end

    it "validates step existence" do
      expect {
        progress.interrupt_step(:invalid_step, "test")
      }.to raise_error(ArgumentError, "Invalid step: invalid_step")
    end
  end

  describe "#summary" do
    let(:progress) { described_class.new }

    before do
      progress.complete_step(:github_setup)
      progress.fail_step(:clone_template, StandardError.new("Failed"))
    end

    it "displays deployment summary" do
      expect {
        progress.summary
      }.to output(/\nDeployment Status:/).to_stdout
    end

    it "shows success status for completed steps" do
      expect {
        progress.summary
      }.to output(/✓ #{described_class::STEPS[:github_setup]}/).to_stdout
    end

    it "shows failure status for failed steps" do
      expect {
        progress.summary
      }.to output(/✗ #{described_class::STEPS[:clone_template]}/).to_stdout
    end
  end
end
