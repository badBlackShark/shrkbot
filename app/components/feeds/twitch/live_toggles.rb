# frozen_string_literal: true

class Components::Feeds::Twitch::LiveToggles < Components::Base
  def initialize(subscription:)
    @subscription = subscription
  end

  def view_template
    toggle(:show_viewers, "viewers", t(".viewers"))
    toggle(:show_preview_frame, "image", t(".preview_frame"))
  end

  private

  def toggle(setting, marker, label)
    render Components::Feeds::Twitch::SettingToggle.new(subscription: @subscription, setting:, marker:, label:)
  end
end
