# frozen_string_literal: true

module Ops
  module Roles
    module Messages
      class Post < ApplicationOperation
        self.transactional = false

        receives :bot, :role_set

        def call
          return ok(role_set) if role_set.channel_id.nil?

          ::Roles::MessagePoster.post(bot, role_set)

          return failure(I18n.t("operations.roles.messages.post_failed")) if role_set.message_id.nil?

          ok(role_set)
        end
      end
    end
  end
end
