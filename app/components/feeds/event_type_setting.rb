# frozen_string_literal: true

class Components::Feeds::EventTypeSetting < Components::Base
  CARD = "group/type px-5 py-4 has-[[data-type-toggle]:checked]:border-accent-soft-bd"
  CHEVRON = "group/chevron hidden size-8 flex-none items-center justify-center rounded-control text-text-secondary " \
    "transition-colors hover:bg-surface-sunken hover:text-text-primary focus:outline-none " \
    "focus-visible:ring-2 focus-visible:ring-[var(--focus-ring)] group-has-[[data-type-toggle]:checked]/type:flex"

  def initialize(subscription:, plugin_key:, event_type:, event:, type_fields: nil)
    @subscription = subscription
    @plugin_key = plugin_key
    @event_type = event_type
    @event = event
    @type_fields = type_fields
  end

  def view_template
    render Components::Card.new(padding: :none, class: CARD, data: card_data) do
      render(Components::SettingRow.new(label:, help: help_text)) do
        chevron
        toggle
      end
      body
    end
  end

  private

  def card_data
    {controller: "type-card", type_card_key_value: storage_key, feed_preview_scope: true}
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

  def body_id
    "feeds-type-#{key}-settings"
  end

  def help_text
    help_key = "components.feeds.event_types.#{key}.help"
    t(help_key) if I18n.exists?(help_key)
  end

  def followed?
    @event.present? && !@event.marked_for_destruction?
  end

  def chevron
    button(
      type: "button",
      class: CHEVRON,
      aria_label: t(".settings_label", type: label),
      aria_expanded: "false",
      aria_controls: body_id,
      data: {type_card_target: "chevron", action: "type-card#flip"}
    ) do
      render Components::Icon.new("caret-down", class: "size-4 motion-safe:transition-transform group-aria-expanded/chevron:rotate-180")
    end
  end

  def toggle
    render Components::Toggle.new(
      name: "subscription[event_types][#{@event_type}]",
      checked: followed?,
      label:,
      data: {type_toggle: true, type_card_target: "toggle", action: "change->type-card#sync"}
    )
  end

  def body
    div(id: body_id, hidden: true, class: "mt-4 flex flex-col gap-4 pb-1", data: {type_card_target: "body"}) do
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
