# frozen_string_literal: true

class Components::SegmentedControl < Components::Base
  ACTIVE = "border-accent bg-accent-soft text-accent-soft-fg font-semibold"
  INACTIVE = "border-border-default text-text-secondary font-medium"
  BASE = "flex-1 h-10 rounded-control border-[1.5px] text-sm transition-colors"

  def initialize(name:, value:, options:, label:, input_data: {})
    @name = name
    @value = value.to_s
    @options = options
    @label = label
    @input_data = input_data
  end

  def view_template
    div(
      role: "radiogroup",
      aria_label: @label,
      class: "flex gap-2",
      data: {
        controller: "segmented",
        action: "keydown->segmented#keydown",
        segmented_active_class: ACTIVE,
        segmented_inactive_class: INACTIVE
      }
    ) do
      input(type: "hidden", name: @name, value: @value, autocomplete: "off", data: {segmented_target: "input", **@input_data})
      @options.each { |opt| option_button(opt) }
    end
  end

  private

  def option_button(opt)
    active = opt[:value].to_s == @value
    tabbable = active || (!selected? && opt.equal?(@options.first))
    button(
      type: "button",
      role: "radio",
      aria_checked: active.to_s,
      tabindex: tabbable ? 0 : -1,
      data: {segmented_target: "option", value: opt[:value], action: "segmented#select"},
      class: "#{BASE} #{active ? ACTIVE : INACTIVE}"
    ) { opt[:label] }
  end

  def selected?
    @options.any? { |opt| opt[:value].to_s == @value }
  end
end
