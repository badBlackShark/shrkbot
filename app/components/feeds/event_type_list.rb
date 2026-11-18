# frozen_string_literal: true

class Components::Feeds::EventTypeList < Components::Base
  def initialize(subscription:, plugin_key:, type_fields: nil)
    @subscription = subscription
    @plugin_key = plugin_key
    @type_fields = type_fields
  end

  def view_template
    ::Feeds.source(@plugin_key).event_types.each { |event_type| event_type_row(event_type) }
  end

  private

  def event_type_row(event_type)
    render Components::Feeds::EventTypeSetting.new(
      subscription: @subscription,
      plugin_key: @plugin_key,
      event_type:,
      event: events_by_type[event_type],
      channel_labels:,
      role_names:,
      type_fields: @type_fields
    )
  end

  def channel_labels
    @channel_labels ||= ChannelOptions.new(@subscription.server_configuration).labels_by_id
  end

  def role_names
    @role_names ||= ServerRoleOptions.new(@subscription.server_configuration).names_by_id
  end

  def events_by_type
    @events_by_type ||= @subscription.subscribed_events.index_by(&:event_type)
  end
end
