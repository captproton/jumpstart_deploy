# frozen_string_literal: true

module JumpstartDeploy
  class CardComponent < ViewComponent::Base
    def initialize(title:, content: nil)
      @title = title
      @content = content
    end

    private

    attr_reader :title, :content
  end
end
