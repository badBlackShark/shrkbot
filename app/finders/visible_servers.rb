# frozen_string_literal: true

require "digest"

module Finders
  class VisibleServers
    CACHE_TTL = 30.seconds
    REJECTED = :rejected

    def self.for(discord_token, discord_id)
      organiser_servers = Finders::TwilightStruggle::OrganiserServers.discord_ids_for(discord_id)
      member_servers(discord_token).select { |server| server.manageable? || organiser_servers.include?(server.id) }
    end

    def self.member_servers(discord_token)
      servers = Rails.cache.fetch(cache_key(discord_token), expires_in: CACHE_TTL) { fetch_servers(discord_token) }
      raise Bot::Discord::UserGuilds::Unauthorized, "Discord rejected the access token" if servers == REJECTED

      servers
    end
    private_class_method :member_servers

    def self.fetch_servers(discord_token)
      Bot::Discord::UserGuilds.call(discord_token).sort_by { |server| -server.member_count.to_i }
    rescue Bot::Discord::UserGuilds::Unauthorized
      REJECTED
    end
    private_class_method :fetch_servers

    def self.cache_key(discord_token)
      "member_guilds:#{Digest::SHA256.hexdigest(discord_token.to_s)}"
    end
    private_class_method :cache_key
  end
end
