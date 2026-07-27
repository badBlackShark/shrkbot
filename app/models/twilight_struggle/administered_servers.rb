# frozen_string_literal: true

module TwilightStruggle
  class AdministeredServers
    def self.discord_ids_for(discord_id)
      new(discord_id).discord_ids
    end

    def initialize(discord_id)
      @discord_id = discord_id
    end

    def discord_ids
      return Set.new if tournament_ids.empty?

      granted_servers.pluck(:discord_id).to_set
    end

    private

    def granted_servers
      ::ServerConfiguration
        .where(id: Destination.active.where(tournament_id: tournament_ids).select(:server_configuration_id))
        .where(id: ::BespokePluginGrant.where(plugin_key: PLUGIN_KEY).select(:server_configuration_id))
    end

    def tournament_ids
      @tournament_ids ||= with_descendants(TournamentAdmin.where(discord_id: @discord_id).pluck(:tournament_id))
    end

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
