# frozen_string_literal: true

class Components::Feeds::Twitch::TypeFields < Components::Base
  def initialize(subscription:, event_type:)
    @subscription = subscription
    @event_type = event_type
  end

  def view_template
    render Components::Callout.new(variant: :warning) { t(".clip_warning") } if clips?
    div do
      render Components::Feeds::RoleField.new(
        subscription: @subscription,
        name: "subscription[#{::Feeds::Twitch::Settings::ROLE_COLUMNS.fetch(@event_type)}]",
        selected: @subscription.settings.role_id_for(@event_type)
      )
    end
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
