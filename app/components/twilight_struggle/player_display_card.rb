# frozen_string_literal: true

class Components::TwilightStruggle::PlayerDisplayCard < Components::Base
  def initialize(destination:, inherited:)
    @destination = destination
    @inherited = inherited
  end

  def view_template
    render Components::Card.new do
      p(class: "text-sm font-semibold") { t(".label") }
      p(class: "mb-3 mt-0.5 text-sm text-text-secondary") { t(".help") }
      render Components::SegmentedControl.new(
        name: "destination[player_display]",
        value: current,
        input_data: {twilight_struggle_preview_target: "display"},
        options:
      )
      inherit_note
    end
  end

  private

  def parent
    @inherited.inherited_from
  end

  def options
    choices = ::TwilightStruggle::Destination::PLAYER_DISPLAYS.map { |value| {value:, label: t(".#{value}")} }
    return choices unless parent

    [{value: "", label: t(".inherit")}, *choices]
  end

  def current
    return "" if parent && @destination.player_display.nil?

    @destination.player_display || ::TwilightStruggle::Destination::DEFAULT_PLAYER_DISPLAY
  end

  def inherit_note
    return unless parent

    p(class: "mt-2 text-xs text-text-secondary") do
      t(".inherits_from", parent: parent.name, setting: t(".#{@inherited.player_display}"))
    end
  end
end
