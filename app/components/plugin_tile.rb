# frozen_string_literal: true

# The chamfered plugin-identity tile: a Phosphor glyph on a filled teal field
# when enabled (Fill weight, per the one-tone rule), or a muted sand field when
# not. Carries the chamfer geometry reserved for brand-forward surfaces.
class Components::PluginTile < Components::Base
  SIZES = {
    sm: {box: "size-9", icon: "size-4"},
    md: {box: "size-11", icon: "size-5"},
    lg: {box: "size-12", icon: "size-6"}
  }.freeze

  def initialize(icon:, enabled: true, size: :md)
    @icon = icon
    @enabled = enabled
    @size = SIZES.fetch(size)
  end

  def view_template
    span(class: "chamfer-tile flex flex-none items-center justify-center #{box}") do
      render Components::Icon.new(@icon, weight: weight, class: @size[:icon])
    end
  end

  private

  def box
    tone = @enabled ? "bg-accent-fill text-white" : "bg-surface-sunken text-text-muted"
    "#{@size[:box]} #{tone}"
  end

  def weight
    @enabled ? :fill : :regular
  end
end
