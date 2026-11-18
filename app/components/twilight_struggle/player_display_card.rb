# frozen_string_literal: true

class Components::TwilightStruggle::PlayerDisplayCard < Components::TwilightStruggle::SettingCardBase
  TAG_NOTE = "hidden group-has-[[data-value=tag][aria-checked=true]]/setting:block " \
    'group-has-[[data-value=name\_and\_tag][aria-checked=true]]/setting:block'

  private

  def help
  end

  def control
    render Components::SegmentedControl.new(
      name: "destination[player_display]",
      value: current,
      label: t(".label"),
      input_data: {twilight_struggle_preview_target: "display"},
      options:
    )
    div(class: TAG_NOTE) { render Components::FieldHelp.new { t(".tag_note") } }
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
