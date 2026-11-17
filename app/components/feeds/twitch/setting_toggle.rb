# frozen_string_literal: true

class Components::Feeds::Twitch::SettingToggle < Components::Base
  def initialize(subscription:, setting:, marker:, label:)
    @subscription = subscription
    @setting = setting
    @marker = marker
    @label = label
  end

  def view_template
    render Components::ToggleRow.new(
      name: "subscription[#{@setting}]",
      checked: @subscription.settings.public_send(@setting),
      label: @label,
      data: {setting_toggle: @marker}
    )
  end
end
