# frozen_string_literal: true

class Components::Feeds::EventTypeSetting < Components::Base
  CARD = "group/type relative has-[[data-type-toggle]:checked]:border-accent-soft-bd"
  HEADER = "cursor-pointer list-none select-none py-4 pl-5 pr-20 [&::-webkit-details-marker]:hidden"

  def initialize(subscription:, plugin_key:, event_type:, event:, channel_labels:, role_names:, type_fields: nil)
    @subscription = subscription
    @plugin_key = plugin_key
    @event_type = event_type
    @event = event
    @channel_labels = channel_labels
    @role_names = role_names
    @type_fields = type_fields
  end

  def view_template
    render Components::Card.new(padding: :none, class: CARD, data: card_data) do
      details(data: {disclosure_target: "details"}) do
        header
        body
      end
      div(class: "absolute right-5 top-4") { toggle }
    end
  end

  private

  def card_data
    {controller: "disclosure", disclosure_key_value: storage_key, feed_preview_scope: true}
  end

  def header
    summary(class: HEADER, data: {action: "click->disclosure#toggle"}) do
      render(Components::SettingRow.new(label:, help: help_text, align: :title)) do
        span(class: "flex h-6 flex-none items-center") do
          render Components::Icon.new("caret-down", class: "dropdown-chevron size-4 text-text-muted")
        end
      end
      override_summary
    end
  end

  def override_summary
    render Components::Feeds::OverrideSummary.new(
      channel_id: @event&.channel_id,
      role_id: ::Feeds.source(@plugin_key).role_override_for(@subscription, @event_type),
      channel_labels: @channel_labels,
      role_names: @role_names
    )
  end

  def key
    ::Feeds.event_key(@event_type)
  end

  def label
    t("components.feeds.event_types.#{key}.label")
  end

  def storage_key
    "feeds-message-#{@subscription.watch.external_id}-#{key}"
  end

  def help_text
    help_key = "components.feeds.event_types.#{key}.help"
    t(help_key) if I18n.exists?(help_key)
  end

  def followed?
    @event.present? && !@event.marked_for_destruction?
  end

  def toggle
    render Components::Toggle.new(
      name: "subscription[event_types][#{@event_type}]",
      checked: followed?,
      label:,
      data: {type_toggle: true, action: "change->disclosure#follow"}
    )
  end

  def body
    div(class: "flex flex-col gap-4 px-5 pb-5") do
      if @type_fields
        render(type_fields) { message_fields }
      else
        render override_fields
        message_fields
      end
    end
  end

  def type_fields
    @type_fields.new(subscription: @subscription, event_type: @event_type, event: @event)
  end

  def override_fields
    Components::Feeds::OverrideFields.new(subscription: @subscription, event_type: @event_type, event: @event)
  end

  def message_fields
    render Components::Feeds::MessageFields.new(
      subscription: @subscription,
      plugin_key: @plugin_key,
      event_type: @event_type,
      event: @event
    )
  end
end
