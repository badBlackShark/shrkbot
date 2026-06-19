module Ops
  module Reminders
    class Create < ApplicationOperation
      receives :user_id, :channel_id, :message, :duration
      receives :server_id, optional: true
      receives :deliver_via_dm, default: false

      def call
        span = ::Reminders::Duration.parse(duration)
        return failure("I couldn't understand that duration. Try something like `1d2h30m`.") unless span
        return failure("A reminder needs a message.") if message.blank?

        remind_at = Time.current + span
        reminder = ::Reminders::Reminder.create!(
          user_id: user_id,
          channel_id: channel_id,
          server_id: server_id,
          message: ::Reminders::Sanitizer.call(message),
          remind_at: remind_at,
          deliver_via_dm: deliver_via_dm
        )
        ::Reminders::DeliverJob.set(wait_until: remind_at).perform_later(reminder.id)
        ok(reminder)
      end
    end
  end
end
