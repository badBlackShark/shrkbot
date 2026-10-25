# frozen_string_literal: true

class Components::Feeds::SubscriptionForm < Components::Base
  def initialize(subscription:, plugin_key:, error: nil)
    @subscription = subscription
    @plugin_key = plugin_key
    @error = error
  end

  def view_template
    render Components::ConfigSections.new(key: @plugin_key.to_s, enable_error: @error) do
      render Components::Feeds::SubscriptionFields.new(subscription: @subscription, plugin_key: @plugin_key)
      stop_following_button if @subscription.persisted?
    end
  end

  private

  def stop_following_button
    div { render Components::Feeds::StopFollowingButton.new(subscription: @subscription) }
  end
end
