# frozen_string_literal: true

module Ops
  module TwilightStruggle
    module Games
      class Destroy < ApplicationOperation
        self.transactional = false

        receives :game

        def call
          locations = game.posted_messages.pluck(:discord_channel_id, :discord_message_id)
          game.destroy!
          locations.each { |channel_id, message_id| ::TwilightStruggle::DeleteMessageJob.perform_later(channel_id, message_id) }
          ok
        end
      end
    end
  end
end
