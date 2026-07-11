# frozen_string_literal: true

module BotConfig
  ACCENT_COLOR = 0x37a79e
  API_VERSION = "v10"

  module_function

  def token
    ENV.fetch("DISCORD_TOKEN")
  end

  def rest_token
    token.start_with?("Bot ") ? token : "Bot #{token}"
  end

  def owner_id
    ENV["OWNER_ID"]
  end

  def owner_guild_id
    ENV["OWNER_GUILD_ID"]
  end

  def redis_url
    ENV["REDIS_URL"]
  end

  def shard_count
    [ENV.fetch("SHARD_COUNT", "1").to_i, 1].max
  end

  def client_id
    ENV["CLIENT_ID"]
  end

  def invite_url
    "https://discord.com/oauth2/authorize?client_id=#{client_id}"
  end

  def web_base_url
    ENV.fetch("WEB_BASE_URL")
  end

  def server_config_url(discord_id)
    "#{web_base_url.chomp("/")}/servers/#{discord_id}"
  end
end
