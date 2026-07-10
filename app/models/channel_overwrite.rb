# frozen_string_literal: true

class ChannelOverwrite < ApplicationRecord
  belongs_to :server_channel

  validates :target_id, presence: true, uniqueness: {scope: :server_channel_id}
  validates :target_type, presence: true
  string_enum :target_type, %w[role member], validate: {allow_nil: true}
end
