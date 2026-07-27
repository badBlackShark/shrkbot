# frozen_string_literal: true

class Servers::TwilightStruggle::DestinationsController < Servers::TwilightStruggle::BaseController
  include VerifiesGuildChannels

  def edit
    render Views::Servers::TwilightStruggle::Destinations::Edit.new(
      user: current_user,
      destination: @destination,
      destinations: switchable_destinations,
      enabled: plugin_enabled?
    )
  end

  def update
    return head :not_found unless guild_channels?(destination_params[:discord_channel_id])

    result = Ops::TwilightStruggle::Destinations::Save.call(
      destination: @destination,
      active: destination_params[:subscribed],
      discord_channel_id: destination_params[:discord_channel_id],
      template_win: destination_params[:template_win],
      template_tie: destination_params[:template_tie],
      template_video: destination_params[:template_video],
      ping_players: destination_params[:ping_players],
      archived: destination_params[:archived]
    )
    respond_with_save(result)
  end

  private

  def switchable_destinations
    @server_configuration.twilight_struggle_destinations
      .active
      .where(tournament: authorized_tournaments)
      .includes(:tournament)
  end

  def configuration_url
    edit_server_twilight_struggle_destination_path(params[:server_id], @destination.tournament)
  end

  def destination_params
    params.expect(
      destination: [:subscribed, :discord_channel_id, :template_win, :template_tie, :template_video, :ping_players, :archived]
    )
  end
end
