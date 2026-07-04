# frozen_string_literal: true

class ManageableGuilds
  def self.for(discord_token)
    Discord::UserGuilds.call(discord_token)
      .select(&:manageable?)
      .sort_by { |guild| -guild.member_count.to_i }
  end
end
