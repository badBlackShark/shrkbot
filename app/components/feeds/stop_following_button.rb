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
      href: server_steam_news_subscription_path(@subscription.server_configuration.discord_id, @subscription),
      data: {turbo_method: :delete, turbo_confirm: t(".confirm", name: @subscription.watch.name)}
    )
  end
end
