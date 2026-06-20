class User < ApplicationRecord
  validates :discord_id, presence: true, uniqueness: true
  validates :username, presence: true

  def self.from_omniauth(auth)
    user = find_or_initialize_by(discord_id: auth.uid)
    user.update!(username: auth.info.name)
    user
  end
end
