# frozen_string_literal: true

module Ops
  module Reminders
    class Create < ApplicationOperation
      MAX_DURATION = 100.years

      receives :user_id, :channel_id, :message, :duration
      receives :server_id, optional: true
      receives :deliver_via_dm, default: false

      def call
        span = ::Reminders::Duration.parse(duration)
        return failure(I18n.t("operations.reminders.invalid_duration")) unless span
        return failure(I18n.t("operations.reminders.duration_too_long")) if span > MAX_DURATION
        return failure(I18n.t("operations.reminders.message_required")) if message.blank?

        remind_at = Time.current + span
        reminder = ::Reminders::Reminder.create!(
          user_id:,
          channel_id:,
          server_id:,
          message: ::Reminders::Sanitizer.call(message),
          remind_at:,
          deliver_via_dm:
        )
        ::Reminders::DeliverJob.set(wait_until: remind_at).perform_later(reminder.id)
        ok(reminder)
      end
    end
  end
end
