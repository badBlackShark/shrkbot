# frozen_string_literal: true

module AuthorizesTournaments
  extend ActiveSupport::Concern

  private

  def administers_every_tournament?
    manages_now?(@server_configuration.discord_id)
  end

  def administered_tournaments
    @administered_tournaments ||= Finders::TwilightStruggle::AdministeredTournaments.new(current_user.discord_id)
  end

  def may_administer?(tournament)
    administers_every_tournament? || administered_tournaments.include?(tournament)
  end

  def authorized_tournaments
    return ::TwilightStruggle::Tournament.all if administers_every_tournament?

    ::TwilightStruggle::Tournament.where(id: administered_tournaments.ids)
  end
end
