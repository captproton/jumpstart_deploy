module JumpstartDeploy
  module ComponentsHelper
    def ui_alert(message, type: :success)
      render AlertComponent.new(message: message, type: type)
    end

    def ui_button(text, variant: :primary)
      render ButtonComponent.new(text: text, variant: variant)
    end

    def ui_card(title:, content: nil, &block)
      render CardComponent.new(title: title, content: content), &block
    end
  end
end
