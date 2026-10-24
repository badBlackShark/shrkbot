# frozen_string_literal: true

class Components::ResetButton < Components::Base
  BUTTON = "inline-flex size-8 items-center justify-center rounded-control border border-border-default " \
    "text-text-secondary transition-colors hover:bg-surface-sunken focus:outline-none " \
    "focus-visible:ring-2 focus-visible:ring-[var(--focus-ring)]"

  def initialize(label:, data:)
    @label = label
    @data = data
  end

  def view_template
    render Components::Tooltip.new(text: @label) do
      button(
        type: "button",
        aria_label: @label,
        class: BUTTON,
        data: @data
      ) do
        render Components::Icon.new("arrow-counter-clockwise", class: "size-4")
      end
    end
  end
end
