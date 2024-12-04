# frozen_string_literal: true

module JumpstartDeploy
  module GitHub
    class Repository
      attr_reader :name, :full_name, :html_url, :ssh_url

      def initialize(attributes)
        @name = attributes.fetch(:name)
        @full_name = attributes.fetch(:full_name)
        @html_url = attributes.fetch(:html_url)
        @ssh_url = attributes.fetch(:ssh_url)
      end

      def clone_url
        @ssh_url
      end

      def to_h
        {
          name: @name,
          full_name: @full_name,
          html_url: @html_url,
          ssh_url: @ssh_url
        }
      end
    end
  end
end