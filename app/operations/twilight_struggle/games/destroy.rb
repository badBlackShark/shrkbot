# frozen_string_literal: true

module Ops
  module TwilightStruggle
    module Games
      class Destroy < ApplicationOperation
        self.transactional = false

        receives :game

        def call
          channel_id = game.discord_channel_id
          message_id = game.discord_message_id
          game.destroy!
          enqueue_delete_message(channel_id, message_id)
          ok
        end

        private

        def enqueue_delete_message(channel_id, message_id)
          return if channel_id.blank? || message_id.blank?

          ::TwilightStruggle::DeleteMessageJob.perform_later(channel_id, message_id)
        end
      end
    end
  end
end
