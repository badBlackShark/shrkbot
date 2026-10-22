# frozen_string_literal: true

class Components::TwilightStruggle::PlayerDisplayCard < Components::TwilightStruggle::SettingCardBase
  private

  def control
    render Components::SegmentedControl.new(
      name: "destination[player_display]",
      value: current,
      input_data: {twilight_struggle_preview_target: "display"},
      options:
    )
  end

  def attribute
    :player_display
  end

  def inherited_values
    {setting: t(".#{@inherited.player_display}")}
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
end
