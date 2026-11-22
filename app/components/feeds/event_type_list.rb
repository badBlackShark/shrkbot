# frozen_string_literal: true

class Components::Feeds::EventTypeList < Components::Base
  def initialize(subscription:, source:, type_fields: nil)
    @subscription = subscription
    @source = source
    @type_fields = type_fields
  end

  def view_template
    @source.event_types.each { |event_type| event_type_row(event_type) }
  end

  private

  def event_type_row(event_type)
    render Components::Feeds::EventTypeSetting.new(
      subscription: @subscription,
      source: @source,
      event_type:,
      event: events_by_type[event_type],
      route_labels:,
      type_fields: @type_fields
    )
  end

  def route_labels
    @route_labels ||= ::Feeds::RouteLabels.new(@subscription.server_configuration)
  end

  def events_by_type
    @events_by_type ||= @subscription.subscribed_events.index_by(&:event_type)
  end
end
