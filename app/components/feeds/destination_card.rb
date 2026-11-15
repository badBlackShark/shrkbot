# frozen_string_literal: true

class Components::Feeds::DestinationCard < Components::Base
  def initialize(subscription:)
    @subscription = subscription
  end

  def view_template
    render Components::Card.new do
      div(class: "flex flex-wrap gap-4") do
        div(class: "flex-1 basis-64") { channel_field }
        div(class: "flex-1 basis-64") { role_field }
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

  def role_field
    render Components::Feeds::RoleField.new(
      subscription: @subscription,
      name: "subscription[role_id]",
      selected: @subscription.settings.role_id,
      label: t(".role_label"),
      placeholder: t(".role_placeholder")
    )
  end
end
