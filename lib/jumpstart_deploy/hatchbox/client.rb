# frozen_string_literal: true

module JumpstartDeploy
  module Hatchbox
    class Client
      API_URL = "https://app.hatchbox.io/api/v1"

      def initialize(token: nil)
        @token = token || ENV["HATCHBOX_API_TOKEN"]
        raise Error, "HATCHBOX_API_TOKEN not set" if @token.nil?
      end

      def post(path, data = {})
        response = connection.post(path) do |req|
          req.headers["Content-Type"] = "application/json"
          req.body = data.to_json
        end
        parse_response(response)
      rescue Faraday::Error => e
        raise Error, "HTTP request failed: #{e.message}"
      end

      def get(path)
        response = connection.get(path)
        parse_response(response)
      rescue Faraday::Error => e
        raise Error, "HTTP request failed: #{e.message}"
      end

      private

      def connection
        @connection ||= Faraday.new(url: API_URL) do |f|
          f.request :authorization, "Bearer", @token
          f.request :retry, { max: 2, interval: 0.05 }
          f.request :json
          f.response :json
          f.adapter Faraday.default_adapter
        end
      end

      def parse_response(response)
        return response.body if response.success?
        
        error_message = response.body["error"] || response.body["message"] || "Request failed"
        raise Error, error_message
      end
    end
  end
end