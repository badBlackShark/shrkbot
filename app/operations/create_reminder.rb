# Validation and persistence layer for reminders; job scheduling is idempotent
# (see Reminders::DeliverJob).
class CreateReminder < ApplicationOperation
  def initialize(user_id:, channel_id:, message:, duration:, server_id: nil, deliver_via_dm: false)
    @user_id = user_id
    @channel_id = channel_id
    @message = message
    @duration = duration
    @server_id = server_id
    @deliver_via_dm = deliver_via_dm
  end

  def call
    span = Reminders::Duration.parse(@duration)
    return failure("I couldn't understand that duration. Try something like `1d2h30m`.") unless span
    return failure("A reminder needs a message.") if @message.blank?

    remind_at = Time.current + span
    reminder = transaction do
      Reminders::Reminder.create!(
        user_id: @user_id,
        channel_id: @channel_id,
        server_id: @server_id,
        message: Reminders::Sanitizer.call(@message),
        remind_at: remind_at,
        deliver_via_dm: @deliver_via_dm
      )
    end

    Reminders::DeliverJob.set(wait_until: remind_at).perform_later(reminder.id)
    ok(reminder)
  end
end
