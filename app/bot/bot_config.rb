# App-level bot config from env (distinct from per-server DB config).
module BotConfig
  module_function

  def token = ENV.fetch("DISCORD_TOKEN")

  # Discord's REST API wants the Authorization header as "Bot <token>". The
  # gateway bot adds this itself, but direct Discordrb::API calls (e.g. from the
  # jobs process) must pass the prefixed form, or Discord returns 401.
  def rest_token
    token.start_with?("Bot ") ? token : "Bot #{token}"
  end

  # Creator override: this user may run any command (incl. owner_only ones).
  def owner_id = ENV["OWNER_ID"]

  # Where :guild commands register until per-server registration lands (Phase 8).
  def test_server_id = ENV["TEST_SERVER_ID"]
end
