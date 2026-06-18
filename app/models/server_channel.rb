class ServerChannel < ApplicationRecord
  belongs_to :server_configuration
  has_many :channel_overwrites, dependent: :delete_all

  validates :discord_id, presence: true, uniqueness: {scope: :server_configuration_id}
  validates :name, presence: true
  validates :channel_type, presence: true

  VIEW_CHANNEL = 1 << 10

  # The @everyone role's id equals the guild id. Channel-level only — ignores
  # category inheritance, so this is advisory, not a guarantee.
  def everyone_visible?
    overwrite = channel_overwrites.find_by(target_id: server_configuration.discord_id)
    return true unless overwrite

    !overwrite.deny.anybits?(VIEW_CHANNEL)
  end
end
