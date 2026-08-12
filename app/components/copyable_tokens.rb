# frozen_string_literal: true

class Components::CopyableTokens < Components::Base
  def view_template(&block)
    div(
      data: {
        controller: "clipboard",
        clipboard_copied_label_value: t(".copied"),
        clipboard_failed_label_value: t(".copy_failed")
      }
    ) do
      yield
      announcer
    end
  end

  private

  def announcer
    span(class: "sr-only", role: "status", data: {clipboard_target: "announcer"})
  end
end
