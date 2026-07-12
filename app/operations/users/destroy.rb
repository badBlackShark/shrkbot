# frozen_string_literal: true

module Ops
  module Users
    class Destroy < ApplicationOperation
      receives :user

      def call
        ::Reminders::Reminder.for_user(user.discord_id).delete_all
        ::Moderation::VerdictRecord.for_user(user.discord_id).delete_all
        user.destroy!
        ok(user)
      end
    end
  end
end
