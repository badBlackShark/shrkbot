module BotConfig
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

  def shard_count
    [ENV.fetch("SHARD_COUNT", "1").to_i, 1].max
  end
end
