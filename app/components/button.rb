# frozen_string_literal: true

class Components::Button < Components::Base
  BASE = "inline-flex items-center justify-center transition-colors"

  VARIANTS = {
    primary: "chamfer-cta bg-accent-fill text-white hover:bg-accent-fill-hover font-semibold",
    secondary: "rounded-control border border-border-strong bg-surface-card hover:bg-surface-sunken font-semibold",
    ghost: "rounded-control text-text-secondary hover:bg-surface-sunken font-semibold",
    danger: "rounded-control bg-danger text-white hover:bg-danger/90 font-semibold"
  }.freeze

  SIZES = {
    sm: "h-8 gap-1.5 px-3 text-xs",
    md: "h-9 gap-1.5 px-3.5 text-sm",
    lg: "h-10 gap-2 px-5 text-sm",
    xl: "h-12 gap-2 px-6 text-base"
  }.freeze

  def self.css(variant: :primary, size: :md, full: false, disabled: false, extra: nil)
    [
      BASE,
      SIZES.fetch(size),
      VARIANTS.fetch(variant),
      (full ? "w-full" : nil),
      (disabled ? "pointer-events-none cursor-not-allowed opacity-50" : nil),
      extra
    ].compact.join(" ")
  end

  def initialize(
    label: nil,
    variant: :primary,
    size: :md,
    href: nil,
    type: "button",
    icon: nil,
    trailing_icon: nil,
    disabled: false,
    full: false,
    **attrs
  )
    @label = label
    @variant = variant
    @size = size
    @href = href
    @type = type
    @icon = icon
    @trailing_icon = trailing_icon
    @disabled = disabled
    @full = full
    @extra = attrs.delete(:class)
    @attrs = attrs
  end

  def view_template(&block)
    if @href
      a(href: @href, class: css, **@attrs) { content(&block) }
    else
      button(type: @type, class: css, disabled: @disabled, **@attrs) { content(&block) }
    end
  end

  private

  def content(&block)
    render Components::Icon.new(@icon, class: icon_size) if @icon
    if block
      yield
    elsif @label
      span { @label }
    end
    render Components::Icon.new(@trailing_icon, class: icon_size) if @trailing_icon
  end

  def css
    self.class.css(variant: @variant, size: @size, full: @full, disabled: @disabled, extra: @extra)
  end

  def icon_size
    (@size == :sm) ? "size-3.5" : "size-4"
  end
end
