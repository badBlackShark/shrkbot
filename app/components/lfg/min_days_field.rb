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
      render Components::NumberStepper.new(
        name: @name,
        value: @value,
        min: 0,
        max: 3650,
        unit: @unit,
        placeholder: @placeholder,
        input_class: "w-28"
      )
      p(class: "mt-1.5 text-xs text-text-muted") { @help }
    end
  end
end
