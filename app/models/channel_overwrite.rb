# frozen_string_literal: true

class ChannelOverwrite < ApplicationRecord
  belongs_to :server_channel

  validates :target_id, presence: true, uniqueness: {scope: :server_channel_id}
  validates :target_type, presence: true
  enum :target_type, {role: "role", member: "member"}, validate: {allow_nil: true}
end
