# frozen_string_literal: true

module TwilightStruggle
  class TaggableReport
    def initialize(report, guild_id)
      @report = report
      @guild_id = guild_id
    end

    def report
      @report.with(usa: taggable(@report.usa), ussr: taggable(@report.ussr))
    end

    private

    def taggable(player)
      return player if player.discord_id.blank? || on_server?(player)

      player.with(discord_id: nil)
    end

    def on_server?(player)
      Bot::Discord::GuildMembership.user_member?(@guild_id, player.discord_id)
    end
  end
end
