# frozen_string_literal: true

require "spec_helper"

RSpec.describe JumpstartDeploy::DeploymentProgress do
  let(:spinner_multi) { instance_double(TTY::Spinner::Multi) }
  let(:step_spinners) { {} }
  let(:registered_spinners) { {} }

  before do
    allow(TTY::Spinner::Multi).to receive(:new).and_return(spinner_multi)

    # Setup registered spinners lookup
    described_class::STEPS.each do |step, message|
      spinner = instance_double(TTY::Spinner)
      allow(spinner).to receive(:auto_spin)
      allow(spinner).to receive(:success)
      allow(spinner).to receive(:error)
      allow(spinner).to receive(:update)
      registered_spinners[step] = spinner

      # Setup spinner registration - allow both formats for testing
      allow(spinner_multi).to receive(:register)
        .with(step)
        .and_return(spinner)
    end

    # Allow output
    $stdout = StringIO.new
  end

  after do
    $stdout = STDOUT
  end

  describe "#initialize" do
    it "sets up spinners for all deployment steps" do
      described_class::STEPS.each do |step, message|
        expect(registered_spinners[step]).to receive(:update).with(title: message)
      end

      # Create new progress instance
      described_class.new
    end
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
      progress.start_step(:github_setup)
      expect(registered_spinners[:github_setup]).to receive(:success)
      progress.complete_step(:github_setup)
    end

    it "updates step status" do
      progress.start_step(:github_setup)
      expect {
        progress.complete_step(:github_setup)
      }.to change { progress.step_statuses[:github_setup] }.to(:complete)
    end
  end

  describe "#fail_step" do
    let(:error) { StandardError.new("Test error") }
    let(:progress) { described_class.new }

    it "marks step as failed" do
      progress.start_step(:github_setup)
      expect(registered_spinners[:github_setup]).to receive(:error)
      progress.fail_step(:github_setup, error)
    end

    it "updates step status" do
      progress.start_step(:github_setup)
      expect {
        progress.fail_step(:github_setup, error)
      }.to change { progress.step_statuses[:github_setup] }.to(:failed)
    end

    it "displays error message" do
      progress.fail_step(:github_setup, error)
      output = $stdout.string
      message = described_class::STEPS[:github_setup]
      expect(output).to include("\nError during #{message}:")
    end

    it "shows troubleshooting steps" do
      expect {
        progress.fail_step(:github_setup, error)
      }.to output(/Troubleshooting steps:/).to_stdout
    end

    context "with different steps" do
      %i[clone_template hatchbox_setup deploy].each do |step|
        it "shows relevant troubleshooting for #{step}" do
          message = described_class::STEPS[step]
          progress.fail_step(step, error)
          output = $stdout.string
          expect(output).to include("\nError during #{message}:")
        end
      end
    end
  end

  describe "#summary" do
    let(:progress) { described_class.new }

    before do
      # Set up test states
      progress.start_step(:github_setup)
      progress.complete_step(:github_setup)
      progress.start_step(:clone_template)
      progress.fail_step(:clone_template, StandardError.new("Failed"))
    end

    it "displays deployment summary" do
      expect {
        progress.summary
      }.to output(/\nDeployment Status:/).to_stdout
    end

    it "shows success status for completed steps" do
      message = described_class::STEPS[:github_setup]
      expect {
        progress.summary
      }.to output(/✓ #{message}/).to_stdout
    end

    it "shows failure status for failed steps" do
      message = described_class::STEPS[:clone_template]
      expect {
        progress.summary
      }.to output(/✗ #{message}/).to_stdout
    end
  end
end