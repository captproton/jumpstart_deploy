module JumpstartDeploy
  class ButtonComponent < ViewComponent::Base
    def initialize(text:, variant: :primary)
      @text = text
      @variant = variant
    end

    private

    attr_reader :text, :variant
  end
end
