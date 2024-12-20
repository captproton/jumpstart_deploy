# Simplify Your Jumpstart Pro Deployments with JumpstartDeploy

The JumpstartDeploy gem provides a streamlined solution for creating and deploying new Jumpstart Pro applications. By automating the setup of a GitHub repository, Hatchbox hosting, and initial application configuration, JumpstartDeploy allows Ruby on Rails developers to focus on building great products rather than managing deployment complexities.

## Installation

Install the gem using:

```bash
$ gem install jumpstart_deploy
```

Or add it to your Gemfile:

```ruby
gem 'jumpstart_deploy', github: 'captproton/jumpstart_deploy'
```

And run:

```bash
$ bundle install
```

## Configuration

Set up the required environment variables:

```bash
# GitHub access token with repo and admin:org scopes
export GITHUB_TOKEN="your_github_token"

# Hatchbox API token with full access
export HATCHBOX_API_TOKEN="your_hatchbox_token"

# URL to your Jumpstart Pro repository
export JUMPSTART_REPO_URL="git@github.com:org/jumpstart-pro.git"
```

## Usage

The gem provides a command-line interface for managing deployments:

```bash
# Show available commands
$ jumpstart_deploy help

# Create and deploy a new application
$ jumpstart_deploy new

# Get help for a specific command
$ jumpstart_deploy help new
```

When creating a new application, you'll be prompted for:
- Application name (required)
- GitHub team name (optional)

The gem will then:
1. Create a new private GitHub repository
2. Clone the Jumpstart Pro repository 
3. Configure application settings
4. Set up Hatchbox deployment

## Secure and Reliable Shell Commands

At the core of JumpstartDeploy is a set of secure shell commands that interact with Git, Rails, and Bundle operations. These commands are carefully whitelisted and validated to ensure the safety and reliability of your deployment workflows, guarding against common security vulnerabilities like command injection.

The shell commands module supports the following operations:

- **Git Commands**: clone, remote, add, commit, push
- **Rails Commands**: db:create, db:migrate, assets:precompile
- **Bundle Commands**: install, exec

By using these pre-built, battle-tested commands, you can be confident that your deployments will be executed consistently and without risk.

## Error Handling

The gem provides clear error messages for common issues:
- Missing environment variables
- Invalid application names
- GitHub permission errors
- Hatchbox configuration issues

All commands can be safely interrupted with Ctrl+C if needed.

## Contributing and Support

The JumpstartDeploy project is open-source and hosted on [GitHub](https://github.com/captproton/jumpstart_deploy). We welcome contributions from the Ruby on Rails community. If you encounter any issues or have suggestions for improvements, please visit the repository to report bugs, submit feature requests, or connect with the project maintainers.

Our team is committed to providing responsive support and ensuring the long-term success of the JumpstartDeploy gem. We encourage you to reach out if you have any questions or need assistance in getting started.

Start streamlining your Jumpstart Pro deployments today with JumpstartDeploy. Automate the setup, focus on your application, and let the gem handle the rest.