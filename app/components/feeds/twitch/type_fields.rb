# frozen_string_literal: true

class Components::Feeds::Twitch::TypeFields < Components::Base
  def initialize(subscription:, event_type:)
    @subscription = subscription
    @event_type = event_type
  end

  def view_template
    render Components::Callout.new(variant: :warning) { t(".clip_warning") } if clips?
    render Components::Feeds::Twitch::RoleField.new(subscription: @subscription, event_type: @event_type)
    return unless live?

    render Components::Feeds::Twitch::EndModeField.new(subscription: @subscription)
    render Components::Feeds::Twitch::ViewersToggle.new(subscription: @subscription)
  end

  private

  def clips?
    @event_type == ::Integrations::Twitch::ClipCreated.name
  end

  def live?
    @event_type == ::Integrations::Twitch::StreamStarted.name
  end
end
