# frozen_string_literal: true

class Components::Feeds::Twitch::SubscriptionFields < Components::Base
  def initialize(subscription:)
    @subscription = subscription
  end

  def view_template
    div(class: "contents", data: {controller: "feed-preview"}) do
      render Components::Feeds::DestinationCard.new(subscription: @subscription)
      render Components::Feeds::EventTypeList.new(
        subscription: @subscription,
        source: ::Feeds::Twitch,
        type_fields: Components::Feeds::Twitch::TypeFields
      )
      render Components::Feeds::Twitch::CategoriesCard.new(subscription: @subscription)
    end
  end
end
