module Ops
  module Reminders
    class Delete < ApplicationOperation
      receives :reminder

      def execute
        reminder.destroy!
        ok(reminder)
      end
    end
  end
end
