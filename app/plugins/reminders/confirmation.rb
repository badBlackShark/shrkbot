# frozen_string_literal: true

module Reminders
  module Confirmation
    module_function

    def call(reminder)
      "I'll remind you <t:#{reminder.remind_at.to_i}:R>:\n>>> #{reminder.message}"
    end
  end
end
