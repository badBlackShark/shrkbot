# frozen_string_literal: true

class Components::Feeds::TwitchCategory::TypeFields < Components::Base
  def initialize(subscription:, event_type:, event:)
    @subscription = subscription
    @event_type = event_type
    @event = event
  end

  def view_template
    render Components::Feeds::OverrideFields.new(subscription: @subscription, event_type: @event_type, event: @event)
    toggle(:show_viewers, "viewers", "components.feeds.twitch.type_fields.viewers_toggle")
    toggle(:show_preview_frame, "image", "components.feeds.twitch.type_fields.preview_frame_toggle")
    yield
    render Components::Feeds::Twitch::EndModeField.new(subscription: @subscription)
    render Components::Feeds::Twitch::SwitchedAwayField.new(subscription: @subscription)
  end

  private

  def toggle(setting, marker, label_key)
    render Components::Feeds::Twitch::SettingToggle.new(subscription: @subscription, setting:, marker:, label: t(label_key))
  end
end
