# spec/lib/jumpstart_deploy/deployment_progress_spec.rb
require "spec_helper"

RSpec.describe JumpstartDeploy::DeploymentProgress do
  let(:progress) { described_class.new }
  let(:spinner) { instance_double(TTY::Spinner) }

  before do
    allow(TTY::Spinner).to receive(:new).with("[:spinner] Creating GitHub repository").and_return(spinner)
    allow(TTY::Spinner).to receive(:new).with("[:spinner] Configuring application").and_return(spinner)
    allow(spinner).to receive(:auto_spin)
    allow(spinner).to receive(:success)
    allow(spinner).to receive(:error)
    allow(progress).to receive(:puts)
  end

  describe "#start" do
    it "starts spinner for step" do
      expect(spinner).to receive(:auto_spin)
      progress.start(:github_setup)
    end
  end

  describe "#success" do
    before { progress.start(:github_setup) }

    it "marks step complete" do
      expect(spinner).to receive(:success)
      progress.success(:github_setup) 
    end
  end

  describe "#error" do
    let(:error) { StandardError.new("Repository creation failed") }
    
    before { progress.start(:github_setup) }

    it "shows error status" do
      expect(spinner).to receive(:error)
      progress.error(:github_setup, error)
    end

    it "includes error message in output" do
      expect(progress).to receive(:puts).with(/Repository creation failed/)
      progress.error(:github_setup, error)
    end
  end

  describe "validation" do
    it "raises error for invalid step" do
      expect { progress.start(:invalid) }.to raise_error(ArgumentError, /Invalid step/)
    end
  end
end