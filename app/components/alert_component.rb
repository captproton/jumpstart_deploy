module JumpstartDeploy
  class AlertComponent < ViewComponent::Base
    def initialize(message:, type: :success)
      @message = message
      @type = type
    end

    private

    attr_reader :message, :type
  end
end