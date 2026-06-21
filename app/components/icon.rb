# frozen_string_literal: true

# Inline Heroicon SVG; maps kit (Lucide) names to Heroicons. See docs/design-system.md.
class Components::Icon < Components::Base
  MAP = {
    "users-round" => "users",
    "hand" => "hand-raised",
    "scroll-text" => "document-text",
    "alarm-clock" => "clock",
    "chevrons-up-down" => "chevron-up-down",
    "log-in" => "arrow-right-on-rectangle",
    "log-out" => "arrow-left-on-rectangle",
    "shield" => "shield-check",
    "lock" => "lock-closed",
    "info" => "information-circle",
    "triangle-alert" => "exclamation-triangle",
    "refresh-cw" => "arrow-path",
    "search" => "magnifying-glass",
    "grip-vertical" => "ellipsis-vertical"
  }.freeze

  def initialize(name, variant: :outline, **options)
    @name = name.to_s
    @variant = variant
    @options = options
    @options[:class] ||= "size-5"
  end

  def view_template
    svg = Heroicons::Icon.render(
      name: MAP.fetch(@name, @name),
      variant: @variant,
      options: @options,
      path_options: {}
    )
    raw(safe(svg.to_s))
  end
end
