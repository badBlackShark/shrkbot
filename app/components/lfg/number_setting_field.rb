# frozen_string_literal: true

class Components::Lfg::NumberSettingField < Components::Base
  def initialize(name:, value:, min:, max:, default:, unit:, label:, help:)
    @name = name
    @value = value
    @min = min
    @max = max
    @default = default
    @unit = unit
    @label = label
    @help = help
  end

  def view_template
    div do
      label(class: "block text-sm font-semibold") { @label }
      p(class: "mb-2 mt-0.5 text-sm text-text-secondary") { @help }
      render Components::NumberStepper.new(
        name: @name,
        value: @value,
        min: @min,
        max: @max,
        default: @default,
        unit: @unit
      )
    end
  end
end
