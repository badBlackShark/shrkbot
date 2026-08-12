# frozen_string_literal: true

class Components::TokenChip < Components::Base
  CHIP = "cursor-pointer rounded bg-surface-sunken px-1.5 py-0.5 font-mono text-xs text-accent-soft-fg " \
    "transition-colors hover:bg-accent-soft focus:outline-none focus-visible:ring-2 focus-visible:ring-[var(--focus-ring)]"

  def initialize(token:, description:)
    @token = "{#{token}}"
    @description = description
  end

  def view_template
    render Components::Tooltip.new(text: @description) do
      button(
        type: "button",
        class: CHIP,
        data: {action: "clipboard#copy", clipboard_text_param: @token}
      ) { @token }
    end
  end
end
