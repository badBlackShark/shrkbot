# frozen_string_literal: true

module TwilightStruggle
  class AccessibleServers
    def initialize(user:, manageable_discord_ids:)
      @user = user
      @manageable_discord_ids = manageable_discord_ids
    end

    def all
      return granted if @user.owner?

      granted.where(discord_id: @manageable_discord_ids)
    end

    private

    def granted
      ::ServerConfiguration
        .joins(:bespoke_plugin_grants)
        .where(bespoke_plugin_grants: {plugin_key: PLUGIN_KEY})
        .order(:name)
    end
  end
end
