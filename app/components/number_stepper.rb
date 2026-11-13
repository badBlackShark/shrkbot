# frozen_string_literal: true

class Components::NumberStepper < Components::Base
  DECREMENT_CORNER = "rounded-l-[7px]"
  TRAILING_CORNER = "rounded-r-[7px] [&:has(+:not([hidden]))]:rounded-r-none"

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
    div(
      class: "flex items-center gap-2",
      data: controller_data
    ) do
      group
      unit_label if @unit
    end
  end

  private

  def group
    div(class: "inline-flex h-8 items-stretch rounded-control border border-border-default bg-surface-card has-[input:focus]:border-accent has-[.ts-wrapper.focus]:border-accent") do
      decrement_button
      number_input
      increment_button
      unit_segment
      reset_segment if resettable?
    end
  end

  def controller_data
    data = {controller: "number-stepper", number_stepper_min_value: @min}
    data[:number_stepper_max_value] = @max if @max
    data[:number_stepper_default_value] = @default if resettable?
    data
  end

  def resettable?
    return false if @default.nil?

    @default.between?(@min, @max || @default)
  end

  def unit_segment
  end

  def shown_attributes
    {name: @name, value: @value, min: @min, max: @max, placeholder: @placeholder}
  end

  def syncs?
    resettable?
  end

  def reset_label
    t(".reset", value: @default)
  end

  def decrement_button
    stepper_button("minus", "decrement", DECREMENT_CORNER)
  end

  def increment_button
    stepper_button("plus", "increment", TRAILING_CORNER)
  end

  def stepper_button(icon, method, corner)
    button(
      type: "button",
      class: "flex w-8 items-center justify-center text-text-secondary transition-colors hover:bg-surface-sunken hover:text-text-primary #{corner}",
      data: {action: "click->number-stepper##{method}"}
    ) do
      render Components::Icon.new(icon, class: "size-4")
    end
  end

  def number_input
    input(
      type: "number",
      step: 1,
      class: "#{@input_class} h-full border-x border-border-default bg-transparent [appearance:textfield] [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none px-1 text-center font-mono text-sm text-text-primary focus:outline-none",
      data: input_data,
      **shown_attributes
    )
  end

  def input_data
    data = {number_stepper_target: "input"}
    data[:action] = "input->number-stepper#sync" if syncs?
    data
  end

  def reset_segment
    span(
      class: "flex",
      hidden: @value == @default,
      data: {number_stepper_target: "reset"}
    ) do
      render Components::ResetButton.new(
        label: reset_label,
        data: {action: "click->number-stepper#reset"},
        shape: :segment
      )
    end
  end

  def unit_label
    span(class: "text-sm text-text-secondary") { @unit }
  end
end
