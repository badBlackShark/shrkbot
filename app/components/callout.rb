# frozen_string_literal: true

# A tinted, bordered notice with a leading icon. variant sets the colour and a
# default icon (overridable); the body is yielded. Used for inline warnings,
# info notes, and confirmations across the config pages.
class Components::Callout < Components::Base
  VARIANTS = {
    info: {box: "bg-accent-soft border-accent-soft-bd", color: "text-accent", icon: "info"},
    neutral: {box: "bg-surface-sunken border-border-default", color: "text-text-muted", icon: "info"},
    warning: {box: "bg-warning-soft border-warning/30", color: "text-warning", icon: "warning"},
    danger: {box: "bg-danger-soft border-danger/30", color: "text-danger", icon: "warning"},
    success: {box: "bg-success-soft border-success/30", color: "text-success", icon: "check"}
  }.freeze

  def initialize(variant: :info, icon: nil, **attrs)
    @variant = VARIANTS.fetch(variant)
    @icon = icon
    @extra = attrs.delete(:class)
    @attrs = attrs
  end

  def view_template(&block)
    div(class: css, **@attrs) do
      render Components::Icon.new(@icon || @variant[:icon], class: "mt-0.5 size-[18px] flex-none #{@variant[:color]}")
      div(class: "text-sm leading-relaxed") { yield }
    end
  end

  private

  def css
    ["flex gap-3 rounded-md border px-4 py-3", @variant[:box], @extra].compact.join(" ")
  end
end
