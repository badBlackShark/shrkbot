# frozen_string_literal: true

class Components::Feeds::MessageFields < Components::Base
  def initialize(subscription:, plugin_key:, event_type:, event:)
    @subscription = subscription
    @plugin_key = plugin_key
    @event_type = event_type
    @event = event
  end

  def view_template
    render Components::PlaceholderSection.new do
      render Components::PlaceholderChips.new(tokens: placeholders)
    end
    render Components::Feeds::CustomMessageField.new(**fields)
    render Components::Feeds::NotificationField.new(**fields)
  end

  private

  def fields
    {subscription: @subscription, plugin_key: @plugin_key, event_type: @event_type, event: @event}
  end

  def placeholders
    ::Feeds.source(@plugin_key).tokens_for(@event_type).index_with do |name|
      t("components.feeds.placeholders.#{@plugin_key}.#{name}")
    end
  end
end
