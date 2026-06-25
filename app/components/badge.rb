# frozen_string_literal: true

class Components::Badge < Components::Base
  VARIANTS = {
    success: {tone: "bg-success-soft text-success", dot: "bg-success"},
    warning: {tone: "bg-warning-soft text-warning", dot: "bg-warning"},
    danger: {tone: "bg-danger-soft text-danger", dot: "bg-danger"},
    neutral: {tone: "bg-surface-sunken text-text-secondary", dot: "bg-text-muted"},
    brand: {tone: "bg-accent-soft text-accent-soft-fg", dot: "bg-accent"},
    copper: {tone: "bg-accent-2-soft text-accent-2-text", dot: "bg-accent-2"}
  }.freeze

  SHAPES = {pill: "rounded-full", chip: "rounded-chip"}.freeze

  def initialize(variant: :neutral, dot: false, shape: :pill, **attrs)
    @variant = VARIANTS.fetch(variant)
    @dot = dot
    @shape = shape
    @extra = attrs.delete(:class)
    @attrs = attrs
  end

  def view_template(&block)
    span(class: css, **@attrs) do
      span(class: "size-1.5 flex-none rounded-full #{@variant[:dot]}") if @dot
      yield
    end
  end

  private

  def css
    [
      "inline-flex items-center gap-1.5 px-2 py-0.5 text-xs font-semibold",
      SHAPES.fetch(@shape),
      @variant[:tone],
      @extra
    ].compact.join(" ")
  end
end
