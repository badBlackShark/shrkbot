# frozen_string_literal: true

class TwilightStruggle::Tournaments::ClaimsController < ApplicationController
  include SetsTwilightStruggleServers

  before_action :load_tournament

  def create
    return head :not_found unless target_server

    result = Ops::TwilightStruggle::Tournaments::Claim.call(
      tournament: @tournament,
      server_configuration: target_server
    )
    redirect_to destination_after(result), **flash_for(result, "claimed")
  end

  def destroy
    return head :not_found unless @tournament.claimed? && manages?(@tournament)

    result = Ops::TwilightStruggle::Tournaments::Release.call(tournament: @tournament)
    redirect_to twilight_struggle_tournaments_path, **flash_for(result, "released")
  end

  private

  def load_tournament
    @tournament = TwilightStruggle::Tournament.find_by(id: params[:tournament_id])
    head :not_found unless @tournament
  end

  def target_server
    return @target_server if defined?(@target_server)

    @target_server = @tournament.claimed? ? nil : @twilight_struggle_servers.find_by(id: params[:server_configuration_id])
  end

  def flash_for(result, success_key)
    return {notice: t("twilight_struggle.#{success_key}")} if result.success?

    {alert: result.errors.to_sentence}
  end

  def destination_after(result)
    return twilight_struggle_tournaments_path if result.failure?

    edit_twilight_struggle_tournament_path(@tournament)
  end
end
