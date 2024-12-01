# frozen_string_literal: true

module JumpstartDeploy
  module GitCommands
    def clone_repository(url, path)
      ShellCommands.git("clone", url, path)
    end

    def configure_remote(remote_url, dir:)
      ShellCommands.git("remote", "remove", "origin", dir: dir)
      ShellCommands.git("remote", "add", "origin", remote_url, dir: dir)
    end

    def initial_commit(dir:)
      ShellCommands.git("add", ".", dir: dir)
      ShellCommands.git("commit", "-m", "Initial Jumpstart Pro setup", dir: dir)
      ShellCommands.git("push", "-u", "origin", "main", dir: dir)
    end
  end
end