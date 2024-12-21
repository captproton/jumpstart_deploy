# Simplify Your Jumpstart Pro Deployments with JumpstartDeploy

The JumpstartDeploy gem provides a streamlined solution for creating and deploying new Jumpstart Pro applications. By automating the setup of a GitHub repository, Hatchbox hosting, and initial application configuration, JumpstartDeploy allows Ruby on Rails developers to focus on building great products rather than managing deployment complexities.

## Getting Started

To use JumpstartDeploy, you'll first need to add the gem to your Gemfile and install the dependencies:

```ruby
gem 'jumpstart_deploy', github: 'captproton/jumpstart_deploy'
```

```
$ bundle install
```

Next, you'll need to set a few environment variables required by the gem:

- `GITHUB_TOKEN`: Your GitHub personal access token
- `HATCHBOX_API_TOKEN`: Your Hatchbox API token
- `JUMPSTART_REPO_URL`: The URL of the Jumpstart Pro repository, which you can find in the [JumpstartDeploy repository](https://github.com/captproton/jumpstart_deploy)

With the environment variables configured, you can use the `jumpstart_deploy new` command to create and deploy a new Jumpstart Pro application:

```
$ jumpstart_deploy new
What's the name of your app? my-new-app
GitHub team name (optional):
```

The gem will handle the rest of the deployment process, including:

1. Creating a new private GitHub repository for your application
2. Cloning the Jumpstart Pro repository and configuring it for your new app
3. Setting up a new Hatchbox application and configuring the environment variables

Once the deployment is complete, JumpstartDeploy will provide you with the URLs for your new GitHub repository and Hatchbox application, allowing you to finalize the setup and trigger your first deployment.

## Secure and Reliable Shell Commands

At the core of JumpstartDeploy is a set of secure shell commands that interact with Git, Rails, and Bundle operations. These commands are carefully whitelisted and validated to ensure the safety and reliability of your deployment workflows, guarding against common security vulnerabilities like command injection.

The shell commands module supports the following operations:

- **Git Commands**: clone, remote, add, commit, push
- **Rails Commands**: db:create, db:migrate, assets:precompile
- **Bundle Commands**: install, exec

By using these pre-built, battle-tested commands, you can be confident that your deployments will be executed consistently and without risk.

## Contributing and Support

The JumpstartDeploy project is open-source and hosted on [GitHub](https://github.com/captproton/jumpstart_deploy). We welcome contributions from the Ruby on Rails community. If you encounter any issues or have suggestions for improvements, please visit the repository to report bugs, submit feature requests, or connect with the project maintainers.

Our team is committed to providing responsive support and ensuring the long-term success of the JumpstartDeploy gem. We encourage you to reach out if you have any questions or need assistance in getting started.

Start streamlining your Jumpstart Pro deployments today with JumpstartDeploy. Automate the setup, focus on your application, and let the gem handle the rest.