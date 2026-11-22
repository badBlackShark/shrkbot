# frozen_string_literal: true

class Components::Feeds::MessageFields < Components::Base
  def initialize(subscription:, source:, event_type:, event:)
    @subscription = subscription
    @source = source
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
    {subscription: @subscription, source: @source, event_type: @event_type, event: @event}
  end

  def placeholders
    @source.tokens_for(@event_type).index_with do |name|
      t("components.feeds.placeholders.#{@source.key}.#{name}")
    end
  end
end
