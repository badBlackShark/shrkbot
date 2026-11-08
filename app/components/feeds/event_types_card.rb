# frozen_string_literal: true

class Components::Feeds::EventTypesCard < Components::Base
  def initialize(subscription:, plugin_key:)
    @subscription = subscription
    @plugin_key = plugin_key
  end

  def view_template(&)
    render Components::Card.new(class: "flex flex-col gap-4") do
      h2(class: "font-semibold") { t(".what_title") }
      yield
      ::Feeds.source(@plugin_key).event_types.each { |event_type| event_type_row(event_type) }
    end
  end

  private

  def event_type_row(event_type)
    render Components::Feeds::EventTypeSetting.new(
      subscription: @subscription,
      plugin_key: @plugin_key,
      event_type:,
      event: events_by_type[event_type]
    )
  end

  def events_by_type
    @events_by_type ||= @subscription.subscribed_events.index_by(&:event_type)
  end
end
