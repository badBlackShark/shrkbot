module BotConfig
  module_function

  def token
    ENV.fetch("DISCORD_TOKEN")
  end

  # Discord's REST API wants the Authorization header as "Bot <token>". The
  # gateway bot adds this itself, but direct Discordrb::API calls (e.g. from the
  # jobs process) must pass the prefixed form, or Discord returns 401.
  def rest_token
    token.start_with?("Bot ") ? token : "Bot #{token}"
  end

  def owner_id
    ENV["OWNER_ID"]
  end

  # Where :guild commands register until per-server registration lands (Phase 8).
  def test_server_id
    ENV["TEST_SERVER_ID"]
  end

  # Static sharding only (no dynamic) — bump SHARD_COUNT to scale without a redeploy.
  def shard_count
    [ENV.fetch("SHARD_COUNT", "1").to_i, 1].max
  end
end
