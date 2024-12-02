require 'thor'

module JumpstartDeploy
  class CLI < Thor
    desc "new", "Create and deploy a new Jumpstart Pro app"
    method_option :name, type: :string, desc: "Name of the application"
    method_option :team, type: :string, desc: "GitHub team to grant access"
    def new(options = {})
      deployer = Deployer.new
      deployer.deploy(options)
    end
  end
end