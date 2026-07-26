# frozen_string_literal: true

class Servers::TwilightStruggle::DestinationsController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin
  include RequiresGrantedPlugin
  include VerifiesGuildChannels

  before_action :load_destination

  def create
    Ops::TwilightStruggle::Destinations::Save.call(destination: @destination)
    redirect_to configuration_url, notice: t("servers.twilight_struggle.subscribed")
  end

  def edit
    render Views::Servers::TwilightStruggle::Destinations::Edit.new(
      user: current_user,
      destination: @destination,
      destinations: @server_configuration.twilight_struggle_destinations.includes(:tournament),
      enabled: plugin_enabled?
    )
  end

  def update
    return head :not_found unless guild_channels?(destination_params[:discord_channel_id])
    return respond_with_save(unsubscribe) unless subscribing?

    result = Ops::TwilightStruggle::Destinations::Save.call(
      destination: @destination,
      discord_channel_id: destination_params[:discord_channel_id],
      template_win: destination_params[:template_win],
      template_tie: destination_params[:template_tie],
      template_video: destination_params[:template_video],
      ping_players: destination_params[:ping_players],
      archived: destination_params[:archived]
    )
    respond_with_save(result)
  end

  def destroy
    unsubscribe
    redirect_to server_twilight_struggle_path(params[:server_id]), notice: t("servers.twilight_struggle.unsubscribed")
  end

  private

  def load_destination
    tournament = ::TwilightStruggle::Tournament.find_by(id: params[:tournament_id])
    return head :not_found unless tournament

    @destination = @server_configuration.twilight_struggle_destinations.find_by(tournament:) ||
      @server_configuration.twilight_struggle_destinations.new(tournament:)
  end

  def subscribing?
    ActiveModel::Type::Boolean.new.cast(destination_params[:subscribed])
  end

  def unsubscribe
    Ops::TwilightStruggle::Destinations::Destroy.call(destination: @destination)
  end

  def plugin_key
    ::TwilightStruggle::PLUGIN_KEY
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
