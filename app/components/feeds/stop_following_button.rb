# frozen_string_literal: true

class Components::Feeds::StopFollowingButton < Components::Base
  def initialize(subscription:, size: :md)
    @subscription = subscription
    @size = size
  end

  def view_template
    render Components::Button.new(
      variant: :danger_outline,
      size: @size,
      label: t(".label"),
      href: ::Feeds::SubscriptionPaths.for(@subscription),
      data: {turbo_method: :delete, turbo_confirm: t(".confirm", name: @subscription.watch.name)}
    )
  end
end
