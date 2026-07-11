# frozen_string_literal: true

class ManageableServers
  def self.for(discord_token)
    Bot::Discord::UserGuilds.call(discord_token)
      .select(&:manageable?)
      .sort_by { |server| -server.member_count.to_i }
  end
end
