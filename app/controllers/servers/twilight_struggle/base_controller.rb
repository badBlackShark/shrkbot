# frozen_string_literal: true

class Servers::TwilightStruggle::BaseController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin
  include AuthorizesTournaments

  before_action :load_destination

  private

  def load_destination
    tournament = ::TwilightStruggle::Tournament.find_by(id: params[:tournament_id])
    return head :not_found unless tournament && may_administer?(tournament)

    @destination = @server_configuration.twilight_struggle_destinations.find_by(tournament:) ||
      @server_configuration.twilight_struggle_destinations.new(tournament:)
  end

  def plugin_key
    ::TwilightStruggle::PLUGIN_KEY
  end
end
