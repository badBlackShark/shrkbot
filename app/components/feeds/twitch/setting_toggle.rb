# frozen_string_literal: true

class Components::Feeds::Twitch::SettingToggle < Components::Base
  def initialize(subscription:, setting:)
    @subscription = subscription
    @setting = setting
  end

  def view_template
    render Components::ToggleRow.new(
      name: "subscription[#{@setting}]",
      checked: @subscription.settings.public_send(@setting),
      label: t(".#{@setting}"),
      data: {setting_toggle: @setting.to_s.dasherize}
    )
  end
end
