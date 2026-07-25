# frozen_string_literal: true

class Components::TwilightStruggle::DestinationActions < Components::Base
  def initialize(destination:, channel_label: nil)
    @destination = destination
    @channel_label = channel_label
  end

  def view_template
    div(class: "flex flex-none items-center gap-2") do
      channel_span
      configure_link
      unsubscribe_link
    end
  end

  private

  def channel_span
    return unless @channel_label

    span(class: "text-sm text-text-secondary") { @channel_label }
  end

  def configure_link
    render Components::Button.new(
      variant: :secondary,
      size: :sm,
      label: t(".configure"),
      href: edit_server_twilight_struggle_destination_path(@destination.server_configuration.discord_id, @destination)
    )
  end

  def unsubscribe_link
    render Components::Button.new(
      variant: :ghost,
      size: :sm,
      label: t(".unsubscribe"),
      href: server_twilight_struggle_destination_path(@destination.server_configuration.discord_id, @destination),
      data: {turbo_method: :delete, turbo_confirm: t(".unsubscribe_confirm")}
    )
  end
end
