# frozen_string_literal: true

class Components::Lfg::MinDaysField < Components::Base
  def initialize(name:, value:, label:, help:, placeholder:, unit:)
    @name = name
    @value = value
    @label = label
    @help = help
    @placeholder = placeholder
    @unit = unit
  end

  def view_template
    div do
      label(class: "mb-1.5 block text-sm font-semibold") { @label }
      div(class: "flex items-center gap-2") do
        input(
          type: "number",
          name: @name,
          value: @value,
          min: 0,
          max: 3650,
          step: 1,
          placeholder: @placeholder,
          class: "h-10 w-32 rounded-control border-[1.5px] border-border-strong bg-surface-card px-3 text-sm " \
            "focus:border-accent focus:outline-none focus:ring-3 focus:ring-[var(--focus-ring)]"
        )
        span(class: "text-sm text-text-secondary") { @unit }
      end
      p(class: "mt-1.5 text-xs text-text-muted") { @help }
    end
  end
end
