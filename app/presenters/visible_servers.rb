# frozen_string_literal: true

require "digest"

class VisibleServers
  CACHE_TTL = 30.seconds

  def self.for(discord_token, discord_id)
    organiser_servers = TwilightStruggle::OrganiserServers.discord_ids_for(discord_id)
    member_servers(discord_token).select { |server| server.manageable? || organiser_servers.include?(server.id) }
  end

  def self.member_servers(discord_token)
    Rails.cache.fetch(cache_key(discord_token), expires_in: CACHE_TTL) do
      Bot::Discord::UserGuilds.call(discord_token).sort_by { |server| -server.member_count.to_i }
    end
  end
  private_class_method :member_servers

  def self.cache_key(discord_token)
    "member_guilds:#{Digest::SHA256.hexdigest(discord_token.to_s)}"
  end
  private_class_method :cache_key
end
