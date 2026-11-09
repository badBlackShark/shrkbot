# frozen_string_literal: true

class Components::Feeds::TypeChannelField < Components::Base
  def initialize(subscription:, event_type:, event:)
    @subscription = subscription
    @event_type = event_type
    @event = event
  end

  def view_template
    div do
      render Components::FieldLabel.new { t(".label") }
      render Components::ChannelSelect.new(
        name: "subscription[channels][#{@event_type}]",
        options: ChannelOptions.new(@subscription.server_configuration).options,
        selected: @event&.channel_id,
        placeholder: t(".placeholder"),
        include_blank: true
      )
    end
  end
end
