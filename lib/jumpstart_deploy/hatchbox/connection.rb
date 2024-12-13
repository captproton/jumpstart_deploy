# frozen_string_literal: true

require "faraday"
require "json"

module JumpstartDeploy
  module Hatchbox
    class Connection
      BASE_URL = "https://app.hatchbox.io/api/v1"
      ALLOWED_METHODS = %i[get post put delete patch].freeze

      attr_reader :client

      def initialize(token = nil)
        @token = token || fetch_token
        validate_token!
        setup_client
      end

      # HTTP Method Helpers
      def get(path, params = {})
        request(:get, path, params)
      end

      def post(path, params = {})
        request(:post, path, params)
      end

      def put(path, params = {})
        request(:put, path, params)
      end

      def delete(path, params = {})
        request(:delete, path, params)
      end

      def patch(path, params = {})
        request(:patch, path, params)
      end

      def request(method, path, params = {})
        method_sym = method.to_s.downcase.to_sym
        validate_method!(method_sym)

        response = perform_request(method_sym, path, params)
        parse_response(response)
      rescue Faraday::Error => e
        raise Error, "Network error: #{e.message}"
      end

      private

      attr_reader :token

      def fetch_token
        ENV.fetch("HATCHBOX_API_TOKEN") do
          raise Error, "HATCHBOX_API_TOKEN environment variable is not set"
        end
      end

      def validate_token!
        raise Error, "Access token cannot be blank" if token.to_s.strip.empty?
      end

      def setup_client
        @client = Faraday.new(url: BASE_URL) do |faraday|
          faraday.headers["Authorization"] = "Bearer #{token}"
          faraday.adapter Faraday.default_adapter
        end
      end

      def validate_method!(method_sym)
        unless ALLOWED_METHODS.include?(method_sym)
          raise Error, "Invalid HTTP method: #{method_sym}"
        end
      end

      def perform_request(method_sym, path, params)
        client.public_send(method_sym, path) do |req|
          if %i[get delete].include?(method_sym)
            req.params = params
          else
            req.body = params.to_json
            req.headers["Content-Type"] = "application/json"
          end
        end
      end

      def parse_response(response)
        body = JSON.parse(response.body)
        return body if response.success?

        error = body["error"] || body["message"] || "Request failed"
        raise Error, error
      end
    end
  end
end
