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
    render Components::Feeds::Twitch::ViewersToggle.new(subscription: @subscription) if live?
    yield
    render Components::Feeds::Twitch::EndModeField.new(subscription: @subscription) if live?
  end

  private

  def role_override
    render Components::Feeds::RoleField.new(
      subscription: @subscription,
      name: "subscription[#{::Feeds::Twitch.fetch_post_type(@event_type).role_column}]",
      selected: @subscription.settings.role_override_for(@event_type),
      label: t(".role_label"),
      placeholder: t(".role_placeholder")
    )
  end

  def live?
    @event_type == ::Integrations::Twitch::StreamStarted.name
  end
end
