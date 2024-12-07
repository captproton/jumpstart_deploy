require 'spec_helper'

RSpec.describe JumpstartDeploy::Deployer do
  let(:deployer) { described_class.new }
  let(:github_client) { instance_double(Octokit::Client) }
  let(:hatchbox_client) { instance_double(JumpstartDeploy::Hatchbox::Client) }
  let(:options) { { "name" => "test_app", "team" => "engineering" } }
  let(:repo_response) do
    double(
      html_url: "https://github.com/org/test_app",
      ssh_url: "git@github.com:org/test_app.git",
      full_name: "org/test_app"
    )
  end

  before do
    allow(Octokit::Client).to receive(:new).and_return(github_client)
    allow(github_client).to receive(:create_repository).and_return(repo_response)
    allow(github_client).to receive(:add_team_repository)
    allow(JumpstartDeploy::ShellCommands).to receive(:git)
    allow(JumpstartDeploy::ShellCommands).to receive(:bundle)
    allow(JumpstartDeploy::ShellCommands).to receive(:rails)

    # Configure deployer
    deployer.instance_variable_set(:@app_name, options["name"])
    deployer.instance_variable_set(:@team_name, options["team"])
  end

  # Previous tests...

  describe "#display_results" do
    let(:hatchbox_app) { { "id" => "123" } }

    before do
      deployer.instance_variable_set(:@repo, repo_response)
      deployer.instance_variable_set(:@hatchbox_app, hatchbox_app)
      # Capture stdout for testing
      @original_stdout = $stdout
      @output = StringIO.new
      $stdout = @output
    end

    after do
      $stdout = @original_stdout
    end

    it "displays GitHub repository URL" do
      deployer.send(:display_results)
      expect(@output.string).to include("GitHub: #{repo_response.html_url}")
    end

    it "displays Hatchbox application URL" do
      deployer.send(:display_results)
      expect(@output.string).to include("Hatchbox: https://app.hatchbox.io/apps/#{hatchbox_app["id"]}")
    end

    it "displays next steps" do
      deployer.send(:display_results)
      expect(@output.string).to include("Next steps:")
      expect(@output.string).to include("1. Set up your database credentials")
      expect(@output.string).to include("2. Configure any additional environment variables")
      expect(@output.string).to include("3. Trigger your first deployment")
    end

    it "adds spacing between sections" do
      deployer.send(:display_results)
      expect(@output.string).to include("\n\n")
    end
  end
end
