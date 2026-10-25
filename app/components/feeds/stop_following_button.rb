# frozen_string_literal: true

class Components::Feeds::StopFollowingButton < Components::Base
  def initialize(subscription:, compact: false)
    @subscription = subscription
    @compact = compact
  end

  def view_template
    if @compact
      render Components::IconButton.new(icon: "trash", label: t(".label_with_name", name: @subscription.watch.name), tone: :danger, href:, data:)
    else
      render Components::Button.new(variant: :danger_outline, label: t(".label_with_name", name: @subscription.watch.name), href:, data:)
    end
  end

  private

  def href
    ::Feeds::SubscriptionPaths.for(@subscription)
  end

  def data
    {
      turbo_method: :delete,
      turbo_confirm: t(".confirm"),
      confirm_title: t(".confirm_title", name: @subscription.watch.name),
      confirm_button: t(".confirm_button")
    }
  end
end
