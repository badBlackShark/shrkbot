# frozen_string_literal: true

CachedGuild = Data.define(:id, :name, :icon_url, :member_count) do
  def self.from(server_configuration)
    new(
      id: server_configuration.discord_id,
      name: server_configuration.name,
      icon_url: server_configuration.icon_url,
      member_count: server_configuration.member_count
    )
  end
end
