# frozen_string_literal: true

module Ops
  module Reminders
    class Update < ApplicationOperation
      receives :reminder, :message

      def call
        return failure(I18n.t("operations.reminders.message_required")) if message.blank?

        reminder.update!(message: ::Reminders::Sanitizer.call(message))
        ok(reminder)
      end
    end
  end
end
