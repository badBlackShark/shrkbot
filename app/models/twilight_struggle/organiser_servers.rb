# frozen_string_literal: true

module TwilightStruggle
  class OrganiserServers
    def self.discord_ids_for(discord_id)
      new(discord_id).discord_ids
    end

    def initialize(discord_id)
      @discord_id = discord_id
    end

    def discord_ids
      return Set.new unless organiser?

      eligible_servers.pluck(:discord_id).to_set
    end

    private

    def organiser?
      TournamentAdmin.exists?(discord_id: @discord_id)
    end

    def eligible_servers
      ::ServerConfiguration
        .where(id: ::BespokePluginGrant.where(plugin_key: PLUGIN_KEY).select(:server_configuration_id))
        .where(id: enabled_activations.select(:server_configuration_id))
    end

    def enabled_activations
      ::PluginActivation.joins(:plugin).where(enabled: true, plugins: {key: PLUGIN_KEY.to_s})
    end
  end
end
