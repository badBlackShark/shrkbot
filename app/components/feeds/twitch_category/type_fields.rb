# frozen_string_literal: true

class Components::Feeds::TwitchCategory::TypeFields < Components::Base
  def initialize(subscription:, event_type:, event:)
    @subscription = subscription
    @event_type = event_type
    @event = event
  end

  def view_template
    render Components::Feeds::OverrideFields.new(subscription: @subscription, event_type: @event_type, event: @event)
    render Components::Feeds::Twitch::LiveToggles.new(subscription: @subscription)
    yield
    render Components::Feeds::Twitch::EndModeField.new(subscription: @subscription)
    render Components::Feeds::Twitch::SwitchedAwayField.new(subscription: @subscription)
  end
end
