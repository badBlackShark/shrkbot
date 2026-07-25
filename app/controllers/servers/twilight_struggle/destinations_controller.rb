# frozen_string_literal: true

class Servers::TwilightStruggle::DestinationsController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin
  include RequiresGrantedPlugin
  include VerifiesGuildChannels

  before_action :load_destination, only: [:edit, :update, :destroy]

  def create
    tournament = ::TwilightStruggle::Tournament.find_by(id: params[:tournament_id])
    return head :not_found unless tournament

    result = Ops::TwilightStruggle::Destinations::Create.call(server_configuration: @server_configuration, tournament:)
    if result.success?
      redirect_to edit_server_twilight_struggle_destination_path(params[:server_id], result.value),
        notice: t("servers.twilight_struggle.subscribed")
    else
      redirect_to server_twilight_struggle_path(params[:server_id]), alert: result.errors.to_sentence
    end
  end

  def edit
    render Views::Servers::TwilightStruggle::Destinations::Edit.new(
      user: current_user,
      destination: @destination,
      destinations: @server_configuration.twilight_struggle_destinations,
      enabled: plugin_enabled?
    )
  end

  def update
    return head :not_found unless guild_channels?(destination_params[:discord_channel_id])

    result = Ops::TwilightStruggle::Destinations::Update.call(
      destination: @destination,
      enabled: destination_params[:enabled],
      discord_channel_id: destination_params[:discord_channel_id],
      template_win: destination_params[:template_win],
      template_tie: destination_params[:template_tie],
      template_video: destination_params[:template_video],
      ping_players: destination_params[:ping_players],
      archived: destination_params[:archived]
    )
    respond_with_configuration(result)
  end

  def destroy
    Ops::TwilightStruggle::Destinations::Destroy.call(destination: @destination)
    redirect_to server_twilight_struggle_path(params[:server_id]), notice: t("servers.twilight_struggle.unsubscribed")
  end

  private

  def load_destination
    @destination = @server_configuration.twilight_struggle_destinations.find_by(id: params[:id])
    return if @destination

    redirect_to server_twilight_struggle_path(params[:server_id]), alert: t("servers.twilight_struggle.destination_not_found")
  end

  def plugin_key
    ::TwilightStruggle::PLUGIN_KEY
  end

  def configuration_url
    edit_server_twilight_struggle_destination_path(params[:server_id], @destination)
  end

  def destination_params
    params.expect(
      destination: [:enabled, :discord_channel_id, :template_win, :template_tie, :template_video, :ping_players, :archived]
    )
  end
end
