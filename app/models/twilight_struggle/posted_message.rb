# frozen_string_literal: true

module TwilightStruggle
  class PostedMessage < ApplicationRecord
    self.table_name = "twilight_struggle_posted_messages"

    belongs_to :game, class_name: "TwilightStruggle::Game"
    belongs_to :server_configuration

    validates :discord_channel_id, presence: true
    validates :discord_message_id, presence: true
    validates :game_id, uniqueness: {scope: :server_configuration_id}
  end
end
