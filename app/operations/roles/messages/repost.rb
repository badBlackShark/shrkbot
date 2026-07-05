# frozen_string_literal: true

module Ops
  module Roles
    module Messages
      class Repost < ApplicationOperation
        self.transactional = false

        receives :bot, :role_set

        def call
          delete_stale_message
          role_set.update!(message_id: nil)
          ::Roles::MessagePoster.post(bot, role_set)

          return failure("Could not post the role message - check the channel.") if role_set.message_id.nil?

          ok(role_set)
        end

        private

        def delete_stale_message
          return if role_set.message_id.nil?

          Delete.call(
            bot:,
            channel_id: role_set.channel_id,
            message_id: role_set.message_id
          )
        end
      end
    end
  end
end
