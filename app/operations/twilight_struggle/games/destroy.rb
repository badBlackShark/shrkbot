# frozen_string_literal: true

module Ops
  module TwilightStruggle
    module Games
      class Destroy < ApplicationOperation
        self.transactional = false

        receives :game

        def call
          delete_message
          game.destroy!
          ok
        end

        private

        def delete_message
          return if game.discord_channel_id.blank? || game.discord_message_id.blank?

          ::Bot::Discord::MessageApi.delete(channel_id: game.discord_channel_id, message_id: game.discord_message_id)
        rescue ::Bot::Discord::MessageApi::Error => error
          Rails.logger.warn("[TwilightStruggle] message #{game.discord_message_id} not deleted: #{error.class}: #{error.message}")
        end
      end
    end
  end
end
