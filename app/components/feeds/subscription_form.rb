# frozen_string_literal: true

class Components::Feeds::SubscriptionForm < Components::Base
  def initialize(subscription:, source:, error: nil)
    @subscription = subscription
    @source = source
    @error = error
  end

  def view_template
    render Components::ConfigSections.new(key: @source.key.to_s, save_error: @error) do
      render "Components::Feeds::#{@source.key.to_s.camelize}::SubscriptionFields".constantize.new(subscription: @subscription)
      stop_following_button if @subscription.persisted?
    end
  end

  private

  def stop_following_button
    div(class: "flex justify-end") { render Components::Feeds::StopFollowingButton.new(subscription: @subscription) }
  end
end
