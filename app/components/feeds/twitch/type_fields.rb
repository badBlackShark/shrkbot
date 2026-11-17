# frozen_string_literal: true

class Components::Feeds::Twitch::TypeFields < Components::Base
  def initialize(subscription:, event_type:, event:)
    @subscription = subscription
    @event_type = event_type
    @event = event
  end

  def view_template
    render(Components::Feeds::OverrideFields.new(subscription: @subscription, event_type: @event_type, event: @event)) do
      role_override
    end
    viewers_toggle if live?
    image_toggle
    yield
    render Components::Feeds::Twitch::EndModeField.new(subscription: @subscription) if live?
  end

  private

  def viewers_toggle
    render Components::Feeds::Twitch::SettingToggle.new(
      subscription: @subscription,
      setting: :show_viewers,
      marker: "viewers",
      label: t(".viewers_toggle")
    )
  end

  def image_toggle
    render Components::Feeds::Twitch::SettingToggle.new(
      subscription: @subscription,
      setting: post_type.image_column,
      marker: "image",
      label: image_toggle_label
    )
  end

  def image_toggle_label
    live? ? t(".preview_frame_toggle") : t(".thumbnail_toggle")
  end

  def post_type
    ::Feeds::Twitch.fetch_post_type(@event_type)
  end

  def role_override
    render Components::Feeds::RoleField.new(
      subscription: @subscription,
      name: "subscription[#{post_type.role_column}]",
      selected: @subscription.settings.role_override_for(@event_type),
      label: t(".role_label"),
      placeholder: t(".role_placeholder"),
      no_ping_label: t(".no_ping")
    )
  end

  def live?
    @event_type == ::Integrations::Twitch::StreamStarted.name
  end
end
