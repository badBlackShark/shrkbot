# frozen_string_literal: true

class Components::Feeds::Twitch::TypeFields < Components::Base
  def initialize(subscription:, event_type:)
    @subscription = subscription
    @event_type = event_type
  end

  def view_template
    render Components::Callout.new(variant: :warning) { t(".clip_warning") } if clips?
    render Components::Callout.new(variant: :info) { t(".featured_window") } if featured?
    div do
      render Components::Feeds::RoleField.new(
        subscription: @subscription,
        name: "subscription[#{::Feeds::Twitch::Settings::ROLE_COLUMNS.fetch(@event_type)}]",
        selected: @subscription.settings.role_id_for(@event_type)
      )
    end
    render Components::Feeds::Twitch::ViewersToggle.new(subscription: @subscription) if live?
    yield
    render Components::Feeds::Twitch::EndModeField.new(subscription: @subscription) if live?
  end

  private

  def clips?
    @event_type == ::Integrations::Twitch::ClipCreated.name
  end

  def featured?
    @event_type == ::Integrations::Twitch::FeaturedClipPublished.name
  end

  def live?
    @event_type == ::Integrations::Twitch::StreamStarted.name
  end
end
