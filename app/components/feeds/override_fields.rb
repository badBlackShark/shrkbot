# frozen_string_literal: true

class Components::Feeds::OverrideFields < Components::Base
  CELL = "flex-1 basis-64"

  def initialize(subscription:, event_type:, event:)
    @subscription = subscription
    @event_type = event_type
    @event = event
  end

  def view_template
    div(class: "flex flex-wrap gap-4") do
      div(class: CELL) { channel_field }
      div(class: CELL) { yield } if block_given?
    end
  end

  private

  def channel_field
    render Components::Feeds::ChannelField.new(
      subscription: @subscription,
      name: "subscription[choices][#{@event_type}][channel_id]",
      selected: @event&.channel_id,
      label: t(".channel_label"),
      placeholder: t(".channel_placeholder")
    )
  end
end
