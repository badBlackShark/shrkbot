# frozen_string_literal: true

module Ops
  module Roles
    module Messages
      class Delete < ApplicationOperation
        self.transactional = false

        receives :bot, :channel_id, :message_id

        def call
          bot.channel(channel_id)&.load_message(message_id)&.delete
          ok
        rescue
          ok
        end
      end
    end
  end
end
