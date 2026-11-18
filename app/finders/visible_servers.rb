# frozen_string_literal: true

require "digest"

module Finders
  class VisibleServers
    CACHE_TTL = 30.seconds
    REJECTIONS = {
      unauthorized: [Integrations::Unauthorized, 1.hour],
      rate_limited: [Integrations::RateLimited, CACHE_TTL]
    }.freeze

    def self.for(discord_token, discord_id)
      organiser_servers = Finders::TwilightStruggle::OrganiserServers.discord_ids_for(discord_id)
      member_servers(discord_token).select { |server| server.manageable? || organiser_servers.include?(server.id) }
    end

    def self.member_servers(discord_token)
      raise Integrations::Unauthorized if discord_token.blank?

      cached = Rails.cache.read(cache_key(discord_token))
      cached = fetch_and_store(discord_token) if cached.nil?
      raise REJECTIONS.fetch(cached).first if cached.is_a?(Symbol)

      cached
    end
    private_class_method :member_servers

    def self.fetch_and_store(discord_token)
      value, ttl = fetch_servers(discord_token)
      Rails.cache.write(cache_key(discord_token), value, expires_in: ttl)
      value
    end
    private_class_method :fetch_and_store

    def self.fetch_servers(discord_token)
      [Bot::Discord::UserGuilds.call(discord_token).sort_by { |server| -server.member_count.to_i }, CACHE_TTL]
    rescue Integrations::Unauthorized
      rejection(:unauthorized)
    rescue Integrations::RateLimited
      rejection(:rate_limited)
    end
    private_class_method :fetch_servers

    def self.rejection(name)
      [name, REJECTIONS.fetch(name).last]
    end
    private_class_method :rejection

    def self.cache_key(discord_token)
      "member_guilds:#{Digest::SHA256.hexdigest(discord_token.to_s)}"
    end
    private_class_method :cache_key
  end
end
