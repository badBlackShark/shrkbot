# frozen_string_literal: true

module TwilightStruggle
  class AdministeredTournaments
    def initialize(discord_id)
      @discord_id = discord_id
    end

    def ids
      @ids ||= with_descendants(TournamentAdmin.where(discord_id: @discord_id).pluck(:tournament_id)).to_set
    end

    def include?(tournament)
      ids.include?(tournament.id)
    end

    private

    def with_descendants(ids)
      found = ids
      frontier = ids

      until frontier.empty?
        frontier = Tournament.where(parent_id: frontier).pluck(:id) - found
        found += frontier
      end

      found
    end
  end
end
