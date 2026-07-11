# frozen_string_literal: true

module Bot
  class GuildCommandSync
    def initialize(bot)
      @bot = bot
    end

    def sync(discord_id)
      overwrite(discord_id, GuildCommandSet.new(discord_id).payloads)
    end

    private

    def overwrite(discord_id, payloads)
      Discordrb::API::Application.bulk_overwrite_guild_commands(
        @bot.token,
        @bot.profile.id,
        discord_id,
        payloads
      )
    rescue => e
      Rails.logger.error("[GuildCommandSync] #{discord_id}: #{e.class}: #{e.message}")
    end
  end
end
