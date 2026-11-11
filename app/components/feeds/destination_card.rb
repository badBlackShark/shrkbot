# frozen_string_literal: true

class Components::Feeds::DestinationCard < Components::Base
  def initialize(subscription:)
    @subscription = subscription
  end

  def view_template(&)
    render Components::Card.new do
      h2(class: "mb-3 font-semibold") { t(".where_title") }
      div(class: "flex flex-wrap gap-4") do
        div(class: "flex-1 basis-64") { channel_field }
        yield if block_given?
      end
    end
  end

  private

  def channel_field
    render Components::Feeds::ChannelField.new(
      subscription: @subscription,
      name: "subscription[channel_id]",
      selected: @subscription.channel_id,
      label: t(".channel_label"),
      placeholder: t(".channel_placeholder"),
      required: true
    )
  end
end
