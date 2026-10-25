# frozen_string_literal: true

class Components::Feeds::EventTypeSetting < Components::Base
  def initialize(subscription:, plugin_key:, event_type:, event:, volume:)
    @subscription = subscription
    @plugin_key = plugin_key
    @event_type = event_type
    @event = event
    @volume = volume
  end

  def view_template
    div(data: {controller: "disclosure", disclosure_key_value: "feeds-message-#{@subscription.watch.external_id}-#{key}"}) do
      render Components::ToggleRow.new(
        name: "subscription[event_types][#{@event_type}]",
        checked: followed?,
        label: t("components.feeds.event_types.#{key}.label"),
        help: help_with_volume,
        data: {action: "change->disclosure#sync", disclosure_target: "toggle"}
      )
      message_disclosure
    end
  end

  private

  def key
    ::Feeds.event_key(@event_type)
  end

  def followed?
    @event.present? && !@event.marked_for_destruction?
  end

  def help_with_volume
    [t("components.feeds.event_types.#{key}.help"), volume_hint].compact.join(" ")
  end

  def volume_hint
    return unless @volume&.sample_size&.positive?

    t(".volume", count: @volume.counts.fetch(@event_type, 0), total: @volume.sample_size)
  end

  def message_disclosure
    details(data: {disclosure_target: "details"}, class: "mt-2") do
      summary(
        class: "flex cursor-pointer list-none select-none items-center gap-1.5 text-sm font-medium " \
          "text-text-secondary [&::-webkit-details-marker]:hidden",
        data: {action: "click->disclosure#toggle"}
      ) do
        span { t(".summary") }
        render Components::Icon.new("caret-down", class: "dropdown-chevron size-3.5 flex-none text-text-muted")
      end
      div(class: "mt-3 flex flex-col gap-3") do
        render Components::Feeds::CustomMessageField.new(
          subscription: @subscription,
          plugin_key: @plugin_key,
          event_type: @event_type,
          event: @event
        )
      end
    end
  end
end
