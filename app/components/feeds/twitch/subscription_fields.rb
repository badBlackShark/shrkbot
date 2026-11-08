# frozen_string_literal: true

class Components::Feeds::Twitch::SubscriptionFields < Components::Base
  def initialize(subscription:)
    @subscription = subscription
  end

  def view_template
    div(class: "contents", data: {controller: "feed-preview"}) do
      render Components::Feeds::DestinationCard.new(subscription: @subscription)
      render Components::Feeds::EventTypesCard.new(
        subscription: @subscription,
        plugin_key: :twitch,
        type_fields: Components::Feeds::Twitch::TypeFields
      )
    end
  end
end
