# frozen_string_literal: true

require "octokit"
require_relative "errors"

module JumpstartDeploy
  module GitHub
    class Connection
      API_VERSION = "2022-11-28"
      DEFAULT_OPTIONS = {
        api_version: API_VERSION,
        auto_paginate: true
      }.freeze

      def initialize(access_token = nil)
        @access_token = access_token || ENV["GITHUB_TOKEN"]
        validate_credentials!
      end

      def client
        @client ||= Octokit::Client.new(client_options)
      end

      private

      def client_options
        DEFAULT_OPTIONS.merge(access_token: @access_token)
      end

      def validate_credentials!
        raise Error, "GitHub access token required" if @access_token.nil?
      end
    end
  end
end