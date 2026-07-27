# frozen_string_literal: true

require "digest"

class ManageableServers
  CACHE_TTL = 30.seconds

  def self.for(discord_token)
    Bot::Discord::UserGuilds.call(discord_token)
      .select(&:manageable?)
      .sort_by { |server| -server.member_count.to_i }
  end

  def self.cached_for(discord_token)
    Rails.cache.fetch(cache_key(discord_token), expires_in: CACHE_TTL) do
      self.for(discord_token)
    end
  end

  def self.cache_key(discord_token)
    "manageable_guilds:#{Digest::SHA256.hexdigest(discord_token.to_s)}"
  end
end
