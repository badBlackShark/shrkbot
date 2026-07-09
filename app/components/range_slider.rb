# frozen_string_literal: true

class Components::RangeSlider < Components::Base
  def initialize(name:, value:, label:, min_caption:, max_caption:, min: 75, max: 100)
    @name = name
    @value = value
    @label = label
    @min_caption = min_caption
    @max_caption = max_caption
    @min = min
    @max = max
  end

  def view_template
    div(
      class: "flex flex-col gap-3",
      data: {controller: "range-slider"}
    ) do
      readout_row
      range_input
      caption_row
      hidden_input
    end
  end

  private

  def hidden_input
    input(
      type: "hidden",
      name: @name,
      value: @value,
      data: {range_slider_target: "hidden"}
    )
  end

  def range_input
    input(
      type: "range",
      min: @min,
      max: @max,
      step: 1,
      value: (@value * 100).round,
      class: "w-full accent-accent",
      aria_label: @label,
      data: {
        range_slider_target: "range",
        action: "input->range-slider#update"
      }
    )
  end

  def readout_row
    div(class: "flex items-center gap-2") do
      span(
        class: "font-mono text-sm font-semibold text-text-primary",
        data: {range_slider_target: "readout"}
      ) { "#{(@value * 100).round}%" }
    end
  end

  def caption_row
    div(class: "flex justify-between text-xs text-text-muted") do
      span { "#{@min}% · #{@min_caption}" }
      span { "#{@max}% · #{@max_caption}" }
    end
  end
end
