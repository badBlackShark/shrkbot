# frozen_string_literal: true

class Components::NumberStepper < Components::Base
  def initialize(name:, value:, min:, default: nil, unit: nil, max: nil, placeholder: nil, input_class: "w-11")
    @name = name
    @value = value
    @min = min
    @default = default
    @unit = unit
    @max = max
    @placeholder = placeholder
    @input_class = input_class
  end

  def view_template
    div(class: "flex flex-col gap-1") do
      stepper_row
      subscript if @default
    end
  end

  private

  def stepper_row
    div(
      class: "flex items-center gap-2",
      data: controller_data
    ) do
      decrement_button
      number_input
      increment_button
      unit_label if @unit
    end
  end

  def controller_data
    data = {controller: "number-stepper", number_stepper_min_value: @min}
    data[:number_stepper_max_value] = @max if @max
    data
  end

  def decrement_button
    button(
      type: "button",
      class: "flex size-8 items-center justify-center rounded-control border border-border-default bg-surface-card text-text-secondary transition-colors hover:bg-surface-sunken hover:text-text-primary",
      data: {action: "click->number-stepper#decrement"}
    ) do
      render Components::Icon.new("minus", class: "size-4")
    end
  end

  def increment_button
    button(
      type: "button",
      class: "flex size-8 items-center justify-center rounded-control border border-border-default bg-surface-card text-text-secondary transition-colors hover:bg-surface-sunken hover:text-text-primary",
      data: {action: "click->number-stepper#increment"}
    ) do
      render Components::Icon.new("plus", class: "size-4")
    end
  end

  def number_input
    input(
      type: "number",
      name: @name,
      value: @value,
      min: @min,
      max: @max,
      step: 1,
      placeholder: @placeholder,
      class: "#{@input_class} [appearance:textfield] [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none rounded-control border border-border-default bg-surface-card px-1 py-1 text-center font-mono text-sm text-text-primary focus:border-accent focus:outline-none",
      data: {number_stepper_target: "input"}
    )
  end

  def unit_label
    span(class: "text-sm text-text-secondary") { @unit }
  end

  def subscript
    p(class: "text-xs text-text-muted") { t(".recommended_default", value: @default) }
  end
end
