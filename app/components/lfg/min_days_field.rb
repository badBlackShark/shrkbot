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
      render Components::FieldLabel.new { @label }
      render Components::NumberStepper.new(
        name: @name,
        value: @value,
        min: 0,
        max: 3650,
        unit: @unit,
        placeholder: @placeholder,
        input_class: "w-28"
      )
      render Components::FieldHelp.new { @help }
    end
  end
end
