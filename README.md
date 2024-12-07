# JumpstartDeploy

Deploy Jumpstart Pro applications with a single command.

## Installation

Add to your Gemfile:
```ruby
gem 'jumpstart_deploy'
```

Or install directly:
```bash
$ gem install jumpstart_deploy
```

## Quick Start

1. Set required environment variables:
```bash
export GITHUB_TOKEN="your_github_token"
export HATCHBOX_API_TOKEN="your_hatchbox_token"
```

2. Create and deploy a new application:
```bash
jumpstart_deploy new
```

This will:
- Create a GitHub repository
- Set up the initial Jumpstart Pro codebase
- Configure and deploy to Hatchbox

## Usage

### Creating a New Application

Basic usage:
```bash
jumpstart_deploy new
```

With options:
```bash
jumpstart_deploy new --name=myapp --team=engineering
```

Options:
- `--name`: Application name (will prompt if not provided)
- `--team`: GitHub team to grant access (optional)

## Environment Variables

Required:
- `GITHUB_TOKEN`: GitHub personal access token
- `HATCHBOX_API_TOKEN`: Hatchbox API token

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/jumpstart_deploy.