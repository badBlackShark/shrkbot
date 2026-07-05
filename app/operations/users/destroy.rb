# frozen_string_literal: true

module Ops
  module Users
    class Destroy < ApplicationOperation
      receives :user

      def call
        ::Reminders::Reminder.where(user_id: user.discord_id).delete_all
        user.destroy!
        ok(user)
      end
    end
  end
end
