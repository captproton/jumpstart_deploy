# spec/lib/jumpstart_deploy/github/repository_spec.rb
require "spec_helper"
require "jumpstart_deploy/github/repository"

RSpec.describe JumpstartDeploy::GitHub::Repository do
  let(:attributes) do
    {
      name: "test-app",
      full_name: "org/test-app",
      html_url: "https://github.com/org/test-app",
      ssh_url: "git@github.com:org/test-app.git"
    }
  end

  let(:repository) { described_class.new(attributes) }

  describe "#initialize" do
    it "sets attributes from hash" do
      expect(repository.name).to eq "test-app"
      expect(repository.full_name).to eq "org/test-app"
      expect(repository.html_url).to eq "https://github.com/org/test-app"
      expect(repository.ssh_url).to eq "git@github.com:org/test-app.git"
    end

    it "requires all attributes" do
      expect { described_class.new({}) }
        .to raise_error(KeyError)
    end
  end

  describe "#clone_url" do
    it "returns ssh url" do
      expect(repository.clone_url).to eq "git@github.com:org/test-app.git"
    end
  end

  describe "#to_h" do
    it "returns attribute hash" do
      expect(repository.to_h).to eq attributes
    end
  end
end