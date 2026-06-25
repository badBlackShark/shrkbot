# frozen_string_literal: true

class Components::Card < Components::Base
  PADDING = {none: "", sm: "p-4", md: "p-5", lg: "p-8"}.freeze

  def initialize(enabled: false, padding: :md, href: nil, lift: false, dashed: false, **attrs)
    @enabled = enabled
    @padding = padding
    @href = href
    @lift = lift
    @dashed = dashed
    @extra = attrs.delete(:class)
    @attrs = attrs
  end

  def view_template(&block)
    if @href
      a(href: @href, class: css, **@attrs) { yield }
    else
      div(class: css, **@attrs) { yield }
    end
  end

  private

  def css
    [
      "rounded-card border bg-surface-card",
      (@dashed ? "border-dashed border-border-strong" : "shadow-sm"),
      (@enabled ? "border-accent-soft-bd" : ("border-border-default" unless @dashed)),
      PADDING.fetch(@padding),
      (@lift ? "card-lift" : nil),
      @extra
    ].compact.join(" ")
  end
end
