class ChannelOverwrite < ApplicationRecord
  belongs_to :server_channel

  validates :target_id, presence: true, uniqueness: {scope: :server_channel_id}
  validates :target_type, presence: true, inclusion: {in: %w[role member]}
end
