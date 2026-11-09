# frozen_string_literal: true

class Components::Feeds::EventTypeSetting < Components::Base
  def initialize(subscription:, plugin_key:, event_type:, event:, type_fields: nil)
    @subscription = subscription
    @plugin_key = plugin_key
    @event_type = event_type
    @event = event
    @type_fields = type_fields
  end

  def view_template
    div(class: "group/type", data: {controller: "disclosure", disclosure_key_value:, feed_preview_scope: true}) do
      render Components::ToggleRow.new(
        name: "subscription[event_types][#{@event_type}]",
        checked: followed?,
        label: t("components.feeds.event_types.#{key}.label"),
        help: help_text,
        data: {action: "change->disclosure#sync", disclosure_target: "toggle"}
      )
      message_disclosure
    end
  end

  private

  def disclosure_key_value
    "feeds-message-#{@subscription.watch.external_id}-#{key}"
  end

  def key
    ::Feeds.event_key(@event_type)
  end

  def help_text
    help_key = "components.feeds.event_types.#{key}.help"
    t(help_key) if I18n.exists?(help_key)
  end

  def followed?
    @event.present? && !@event.marked_for_destruction?
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
        div do
          render Components::Feeds::ChannelField.new(
            subscription: @subscription,
            name: "subscription[choices][#{@event_type}][channel_id]",
            selected: @event&.channel_id,
            label: t(".channel_label"),
            placeholder: t(".channel_placeholder")
          )
        end
        if @type_fields
          render(@type_fields.new(subscription: @subscription, event_type: @event_type)) { message_fields }
        else
          message_fields
        end
      end
    end
  end

  def message_fields
    render Components::Feeds::CustomMessageField.new(
      subscription: @subscription,
      plugin_key: @plugin_key,
      event_type: @event_type,
      event: @event
    )
    render Components::Feeds::NotificationField.new(
      subscription: @subscription,
      plugin_key: @plugin_key,
      event_type: @event_type,
      event: @event
    )
  end
end
