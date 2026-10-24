# frozen_string_literal: true

class Components::IconButton < Components::Base
  BASE = "flex size-8 flex-none items-center justify-center rounded-md text-text-muted transition-colors"

  TONES = {
    danger: "hover:bg-danger-soft hover:text-danger",
    accent: "hover:bg-accent-soft hover:text-accent-soft-fg"
  }.freeze

  def initialize(icon:, label:, tone:, href: nil, **attrs)
    @icon = icon
    @label = label
    @tone = tone
    @href = href
    @attrs = attrs
  end

  def view_template
    render Components::Tooltip.new(text: @label) do
      if @href
        a(href: @href, aria_label: @label, class: css, **@attrs) { icon }
      else
        button(type: "button", aria_label: @label, class: css, **@attrs) { icon }
      end
    end
  end

  private

  def icon
    render Components::Icon.new(@icon, class: "size-4")
  end

  def css
    "#{BASE} #{TONES.fetch(@tone)}"
  end
end
