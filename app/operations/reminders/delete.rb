module Ops
  module Reminders
    class Delete < ApplicationOperation
      receives :reminder

      def call
        reminder.destroy!
        ok(reminder)
      end
    end
  end
end
