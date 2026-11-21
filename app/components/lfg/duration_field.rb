# frozen_string_literal: true

class Components::Lfg::DurationField < Components::Base
  def initialize(name:, value:, min:, max:, default:, base:, label:, help: nil)
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
      render Components::FieldLabel.new { @label }
      render Components::DurationStepper.new(
        name: @name,
        value: @value,
        label: @label,
        min: @min,
        max: @max,
        default: @default,
        base: @base
      )
      render Components::FieldHelp.new { @help } if @help
    end
  end
end
