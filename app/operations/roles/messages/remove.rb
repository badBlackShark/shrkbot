# frozen_string_literal: true

module Ops
  module Roles
    module Messages
      class Remove < ApplicationOperation
        self.transactional = false

        receives :bot, :role_set

        def call
          return ok(role_set) if role_set.message_id.nil?

          Delete.call(
            bot:,
            channel_id: role_set.channel_id,
            message_id: role_set.message_id
          )
          role_set.update!(message_id: nil)
          ok(role_set)
        end
      end
    end
  end
end
