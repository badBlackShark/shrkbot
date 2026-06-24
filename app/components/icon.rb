# frozen_string_literal: true

# Renders a Phosphor icon as inline SVG (inherits `currentColor`).
#
# Weights follow the design system's one-tone rule: `:regular` is the
# workhorse, `:bold` marks active/emphasis states, and `:fill` is the white
# glyph inside a filled teal tile. An unknown icon name raises
# `PhosphorIcons::IconNotFoundError`, so typos surface loudly.
class Components::Icon < Components::Base
  def initialize(name, weight: :regular, **options)
    @name = name.to_s
    @weight = weight
    @options = options
    @options[:class] ||= "size-5"
  end

  def view_template
    raw(safe(PhosphorIcons::Icon.new(@name, style: @weight, **@options).to_svg))
  end
end
