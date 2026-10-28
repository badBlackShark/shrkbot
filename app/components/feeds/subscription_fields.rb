# frozen_string_literal: true

class Components::Feeds::SubscriptionFields < Components::Base
  include Phlex::Rails::Helpers::TurboFrameTag

  def initialize(subscription:, plugin_key:)
    @subscription = subscription
    @plugin_key = plugin_key
  end

  def view_template
    div(class: "contents", data: {controller: "feed-preview"}) do
      destination_card
      event_types_card
      body_length_card
    end
  end

  private

  def destination_card
    render Components::Card.new do
      h2(class: "mb-3 font-semibold") { t(".where_title") }
      div(class: "flex flex-wrap gap-4") do
        div(class: "flex-1 basis-64") { channel_field }
        div(class: "flex-1 basis-64") { role_field }
      end
    end
  end

  def channel_field
    render Components::FieldLabel.new { t(".channel_label") }
    render Components::ChannelSelect.new(
      name: "subscription[channel_id]",
      options: ChannelOptions.new(server_configuration).options,
      selected: @subscription.channel_id,
      placeholder: t(".channel_placeholder"),
      include_blank: true,
      required: true
    )
  end

  def role_field
    render Components::FieldLabel.new { t(".role_label") }
    render Components::RoleSelect.new(
      name: "subscription[role_id]",
      options: ServerRoleOptions.new(server_configuration).options,
      selected: @subscription.role_id,
      placeholder: t(".role_placeholder"),
      multiple: false,
      include_blank: true,
      data: {feed_preview_target: "role", action: "change->feed-preview#render"}
    )
  end

  def event_types_card
    render Components::Card.new(class: "flex flex-col gap-4") do
      h2(class: "font-semibold") { t(".what_title") }
      volume_frame
      render Components::Callout.new(variant: :warning) { t(".#{@plugin_key}.what_note") }
      ::Feeds::EVENT_TYPES_BY_SOURCE.fetch(@plugin_key).each { |event_type| event_type_row(event_type) }
    end
  end

  def volume_frame
    turbo_frame_tag(
      Components::Feeds::VolumeLine::FRAME_ID,
      src: ::Feeds::SubscriptionPaths.volume_for(@subscription),
      loading: "lazy"
    ) do
      p(class: "text-sm text-text-muted") { t(".volume_loading") }
    end
  end

  def event_type_row(event_type)
    render Components::Feeds::EventTypeSetting.new(
      subscription: @subscription,
      plugin_key: @plugin_key,
      event_type:,
      event: events_by_type[event_type]
    )
  end

  def body_length_card
    render Components::Card.new do
      h2(class: "mb-3 font-semibold") { t(".length_title") }
      render Components::RadioCardGroup.new(
        name: "subscription[body_length]",
        value: @subscription.body_length,
        label: t(".length_title"),
        options: ::Feeds::Subscription::BODY_LENGTHS.map { |length| length_option(length) }
      )
    end
  end

  def length_option(length)
    {value: length, title: t(".length.#{length}.title"), description: t(".length.#{length}.description")}
  end

  def events_by_type
    @events_by_type ||= @subscription.subscribed_events.index_by(&:event_type)
  end

  def server_configuration
    @subscription.server_configuration
  end
end
