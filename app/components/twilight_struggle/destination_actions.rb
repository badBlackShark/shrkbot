# frozen_string_literal: true

class Components::TwilightStruggle::DestinationActions < Components::Base
  ACTION_WIDTH = "min-w-28"

  def initialize(tournament:, destination:, server_configuration:, channel_label: nil)
    @tournament = tournament
    @destination = destination
    @server_configuration = server_configuration
    @channel_label = channel_label
  end

  def view_template
    div(class: "flex flex-none items-center gap-2") do
      channel_chip
      configure_link
      subscribed? ? unsubscribe_link : subscribe_link
    end
  end

  private

  def subscribed?
    @destination&.active?
  end

  def channel_chip
    return unless subscribed? && @channel_label

    render Components::ChannelChip.new(label: @channel_label)
  end

  def configure_link
    render Components::Button.new(
      variant: :secondary,
      size: :sm,
      label: t(".configure"),
      href: edit_server_twilight_struggle_destination_path(@server_configuration.discord_id, @tournament)
    )
  end

  def subscribe_link
    render Components::Button.new(
      size: :sm,
      class: ACTION_WIDTH,
      label: t(".subscribe"),
      href: server_twilight_struggle_subscriptions_path(@server_configuration.discord_id, tournament_id: @tournament.id),
      data: {turbo_method: :post}
    )
  end

  def unsubscribe_link
    render Components::Button.new(
      variant: :danger_outline,
      size: :sm,
      class: ACTION_WIDTH,
      label: t(".unsubscribe"),
      href: server_twilight_struggle_subscription_path(@server_configuration.discord_id, @tournament),
      data: {turbo_method: :delete}
    )
  end
end
