# frozen_string_literal: true

class Components::SegmentedControl < Components::Base
  ACTIVE = "border-accent bg-accent-soft text-accent-soft-fg font-semibold"
  INACTIVE = "border-border-default text-text-secondary font-medium"
  BASE = "flex-1 h-10 rounded-control border-[1.5px] text-sm transition-colors"

  def initialize(name:, value:, options:)
    @name = name
    @value = value.to_s
    @options = options
  end

  def view_template
    div(
      class: "flex gap-2",
      data: {controller: "segmented", segmented_active_class: ACTIVE, segmented_inactive_class: INACTIVE}
    ) do
      input(type: "hidden", name: @name, value: @value, data: {segmented_target: "input"})
      @options.each { |opt| option_button(opt) }
    end
  end

  private

  def option_button(opt)
    active = opt[:value].to_s == @value
    button(
      type: "button",
      aria_pressed: active.to_s,
      data: {segmented_target: "option", value: opt[:value], action: "segmented#select"},
      class: "#{BASE} #{active ? ACTIVE : INACTIVE}"
    ) { opt[:label] }
  end
end
