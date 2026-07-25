# frozen_string_literal: true

class Components::TwilightStruggle::SubscribeButton < Components::Base
  def initialize(tournament:, server_configuration:)
    @tournament = tournament
    @server_configuration = server_configuration
  end

  def view_template
    render Components::Button.new(
      size: :sm,
      label: t(".subscribe"),
      href: server_twilight_struggle_destinations_path(@server_configuration.discord_id, tournament_id: @tournament.id),
      data: {turbo_method: :post}
    )
  end
end
