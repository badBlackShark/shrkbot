# frozen_string_literal: true

class Components::RadioCardGroup < Components::Base
  def initialize(name:, value:, options:, label: nil)
    @name = name
    @value = value.to_s
    @options = options
    @label = label
  end

  def view_template
    div(
      role: "radiogroup",
      aria_label: @label,
      class: "flex flex-col gap-3"
    ) do
      @options.each { |opt| radio_card(opt) }
    end
  end

  private

  def radio_card(opt)
    label(class: card_css) do
      input(
        type: "radio",
        name: @name,
        value: opt[:value],
        checked: opt[:value].to_s == @value,
        class: "mt-0.5 size-4 flex-none appearance-none rounded-full border-2 border-border-strong bg-surface-card transition-colors checked:border-[5px] checked:border-accent"
      )
      div do
        p(class: "text-sm font-semibold text-text-primary") { opt[:title] }
        p(class: "mt-0.5 text-xs text-text-secondary") { opt[:description] }
      end
    end
  end

  def card_css
    "flex cursor-pointer items-start gap-3 rounded-card border-[1.5px] " \
      "border-border-default bg-surface-card px-4 py-3 transition-colors " \
      "hover:bg-surface-sunken has-[:checked]:border-accent has-[:checked]:bg-accent-soft"
  end
end
