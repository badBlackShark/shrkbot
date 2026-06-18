module Ops
  module Reminders
    class Delete < ApplicationOperation
      def initialize(reminder_id:, user_id:)
        @reminder_id = reminder_id
        @user_id = user_id
      end

      def call
        reminder = ::Reminders::Reminder.find_by(id: @reminder_id, user_id: @user_id)
        return failure("That reminder doesn't exist.") unless reminder

        transaction do
          reminder.destroy!
        end
        ok(reminder)
      end
    end
  end
end
