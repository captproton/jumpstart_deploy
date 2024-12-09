# frozen_string_literal: true

require "faraday"
require "json"

module JumpstartDeploy
  module Hatchbox
    class Connection
      BASE_URL = "https://app.hatchbox.io/api/v1"
      ALLOWED_METHODS = %i[get post put delete patch].freeze

      def initialize(token = nil)
        @token = token || fetch_token
        setup_client
      end

      def request(method, path, params = {})
        method_sym = method.to_s.downcase.to_sym
        unless ALLOWED_METHODS.include?(method_sym)
          raise JumpstartDeploy::Error, "Invalid HTTP method: #{method}"
        end

        response = perform_request(method_sym, path, params)
        parse_response(response)
      rescue Faraday::Error => e
        raise JumpstartDeploy::Error, "Network error: #{e.message}"
      end

      private

      attr_reader :token, :client

      def fetch_token
        ENV.fetch("HATCHBOX_API_TOKEN") do
          raise JumpstartDeploy::Error, "HATCHBOX_API_TOKEN not configured"
        end
      end

      def setup_client
        @client = Faraday.new(url: BASE_URL) do |faraday|
          faraday.request :json
          faraday.response :json, content_type: /\bjson$/
          faraday.adapter Faraday.default_adapter
          faraday.headers["Authorization"] = "Bearer #{token}"
        end
      end

      def perform_request(method_sym, path, params)
        case method_sym
        when :get
          client.get(path, params)
        when :post
          client.post(path, params)
        when :put
          client.put(path, params)
        when :delete
          client.delete(path, params)
        when :patch
          client.patch(path, params)
        else
          # This should not occur due to prior validation
          raise JumpstartDeploy::Error, "Unsupported HTTP method: #{method_sym}"
        end
      end

      def parse_response(response)
        if response.success?
          response.body
        else
          raise JumpstartDeploy::Error, "API error: #{response.status} #{response.body}"
        end
      end
    end
  end
end
