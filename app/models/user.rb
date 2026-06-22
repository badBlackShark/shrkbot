class User < ApplicationRecord
  validates :discord_id, presence: true, uniqueness: true
  validates :username, presence: true

  def self.from_omniauth(auth)
    raw = auth.extra&.raw_info || {}
    user = find_or_initialize_by(discord_id: auth.uid)
    user.update!(
      username: auth.info.name,
      display_name: raw["global_name"],
      avatar: raw["avatar"]
    )
    user
  end

  def display_name
    self[:display_name].presence || username
  end

  def avatar_url
    return unless avatar

    "https://cdn.discordapp.com/avatars/#{discord_id}/#{avatar}.png"
  end
end
