# frozen_string_literal: true

class TwilightStruggle::TournamentsController < ApplicationController
  include SetsTwilightStruggleServers

  before_action :load_tournament, only: [:edit, :update]

  def index
    render Views::TwilightStruggle::Tournaments::Index.new(
      user: current_user,
      tournaments: tournament_list.all,
      servers: @twilight_struggle_servers,
      archived: archived_filter?
    )
  end

  def edit
    render Views::TwilightStruggle::Tournaments::Edit.new(
      user: current_user,
      tournament: @tournament
    )
  end

  def update
    return head :not_found unless guild_channel?

    result = Ops::TwilightStruggle::Tournaments::Configure.call(
      tournament: @tournament,
      discord_channel_id: tournament_params[:discord_channel_id],
      template_win: tournament_params[:template_win],
      template_tie: tournament_params[:template_tie],
      template_video: tournament_params[:template_video],
      ping_players: tournament_params[:ping_players],
      archived: tournament_params[:archived]
    )
    redirect_to edit_twilight_struggle_tournament_path(@tournament), **flash_for(result, "saved")
  end

  private

  def load_tournament
    @tournament = TwilightStruggle::Tournament.find_by(id: params[:id])
    return if @tournament&.claimed? && manages?(@tournament)

    redirect_to twilight_struggle_tournaments_path, alert: t("twilight_struggle.tournament_not_available")
  end

  def guild_channel?
    channel_id = tournament_params[:discord_channel_id]
    channel_id.blank? || @tournament.server_configuration.server_channels.exists?(discord_id: channel_id)
  end

  def tournament_list
    TwilightStruggle::TournamentList.new(
      server_configurations: @twilight_struggle_servers,
      owner: current_user.owner?,
      archived: archived_filter?
    )
  end

  def archived_filter?
    params[:archived].present?
  end

  def tournament_params
    params.expect(
      tournament: [:discord_channel_id, :template_win, :template_tie, :template_video, :ping_players, :archived]
    )
  end
end
