# frozen_string_literal: true

class Components::Feeds::SubscriptionForm < Components::Base
  def initialize(subscription:, plugin_key:, error: nil, volume: nil)
    @subscription = subscription
    @plugin_key = plugin_key
    @error = error
    @volume = volume
  end

  def view_template
    render Components::ConfigSections.new(key: @plugin_key.to_s, enable_error: @error) do
      render Components::Feeds::SubscriptionFields.new(subscription: @subscription, plugin_key: @plugin_key, volume: @volume)
      stop_following_card if @subscription.persisted?
    end
  end

  private

  def stop_following_card
    render Components::Card.new(class: "flex flex-wrap items-center gap-4") do
      div(class: "min-w-0 flex-1") do
        h2(class: "font-semibold") { t(".stop_title", name: @subscription.watch.name) }
        p(class: "mt-0.5 text-sm text-text-secondary") { t(".stop_body") }
      end
      render Components::Feeds::StopFollowingButton.new(subscription: @subscription)
    end
  end
end
