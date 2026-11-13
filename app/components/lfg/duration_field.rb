# frozen_string_literal: true

class Components::Lfg::DurationField < Components::Base
  def initialize(name:, value:, min:, max:, default:, base:, label:, help:)
    @name = name
    @value = value
    @min = min
    @max = max
    @default = default
    @base = base
    @label = label
    @help = help
  end

  def view_template
    div do
      label(class: "block text-sm font-semibold") { @label }
      p(class: "mb-2 mt-0.5 text-sm text-text-secondary") { @help }
      render Components::DurationStepper.new(
        name: @name,
        value: @value,
        min: @min,
        max: @max,
        default: @default,
        base: @base
      )
    end
  end
end
