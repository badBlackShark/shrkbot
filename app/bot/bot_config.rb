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

  def test_server_id
    ENV["TEST_SERVER_ID"]
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

  def web_base_url
    ENV.fetch("WEB_BASE_URL")
  end

  def server_config_url(discord_id)
    web_url("servers/#{discord_id}")
  end

  def mascot_url
    web_url("icon.png")
  end

  def web_url(path)
    "#{web_base_url.chomp("/")}/#{path}"
  end
end
