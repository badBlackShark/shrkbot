# frozen_string_literal: true

class Components::Feeds::TwitchCategory::SubscriptionFields < Components::Base
  def initialize(subscription:)
    @subscription = subscription
  end

  def view_template
    div(class: "contents", data: {controller: "feed-preview"}) do
      render Components::Feeds::DestinationCard.new(subscription: @subscription)
      render Components::Feeds::EventTypeList.new(
        subscription: @subscription,
        source: ::Feeds::TwitchCategory,
        type_fields: Components::Feeds::TwitchCategory::TypeFields
      )
      render Components::Feeds::TwitchCategory::FiltersCard.new(subscription: @subscription)
    end
  end
end
