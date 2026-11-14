# frozen_string_literal: true

class Components::ResetButton < Components::Base
  BASE = "inline-flex items-center justify-center text-text-secondary transition-colors " \
    "hover:bg-surface-sunken focus:outline-none focus-visible:ring-2 focus-visible:ring-[var(--focus-ring)]"

  SHAPES = {
    standalone: "size-8 rounded-control border border-border-default",
    segment: "w-8 rounded-r-[7px] #{Components::NumberStepper::SEGMENT}"
  }.freeze

  def initialize(label:, data:, shape: :standalone)
    @label = label
    @data = data
    @shape = SHAPES.fetch(shape)
  end

  def view_template
    render Components::Tooltip.new(text: @label) do
      button(
        type: "button",
        aria_label: @label,
        class: "#{BASE} #{@shape}",
        data: @data
      ) do
        render Components::Icon.new("arrow-counter-clockwise", class: "size-4")
      end
    end
  end
end
