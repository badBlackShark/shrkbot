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
      render Components::FieldLabel.new { @label }
      render Components::NumberStepper.new(
        name: @name,
        value: @value,
        min: @min,
        max: @max,
        default: @default,
        unit: @unit
      )
      render Components::FieldHelp.new { @help }
    end
  end
end
