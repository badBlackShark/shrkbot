# frozen_string_literal: true

if ENV["WEB_DEBUG"] && Rails.env.development?
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:discord] = OmniAuth::AuthHash.new(
    provider: "discord",
    uid: "12345",
    info: {name: "shrk"},
    credentials: {token: "web-debug-token"}
  )

  Rails.application.config.to_prepare do
    Bot::Discord::UserGuilds.define_singleton_method(:call) do |*|
      [
        Bot::Discord::Guild.new(
          id: 900_000_001,
          name: "Dev Refuge",
          owner: true,
          permissions: 0,
          icon: nil,
          member_count: 5
        )
      ]
    end
  end

  Rails.application.config.after_initialize do
    PluginCatalog.all.each do |definition|
      Plugin.find_or_create_by!(key: definition.key) do |record|
        record.name = definition.name
        record.description = definition.description
      end
    end
    config = Ops::ServerConfiguration::Ensure.call(discord_id: 900_000_001).value
    config.logging_settings.update!(channel_id: 111) unless config.logging_settings.channel_id
    unless config.server_roles.exists?(discord_id: 500)
      config.server_roles.create!(discord_id: 500, name: "Moderator", color: 0xE67E22, position: 1)
    end
    unless config.server_channels.exists?(discord_id: 111)
      config.server_channels.create!(discord_id: 111, name: "mod-log", channel_type: 0)
    end
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
    warn "web_debug: database not ready, seed skipped — run bin/rails db:prepare first"
  end
end
