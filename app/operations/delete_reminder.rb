# No job cancellation: DeliverJob guards on row existence, so deletion just
# no-ops when the job fires.
class DeleteReminder < ApplicationOperation
  def initialize(reminder_id:, user_id:)
    @reminder_id = reminder_id
    @user_id = user_id
  end

  def call
    reminder = Reminders::Reminder.find_by(id: @reminder_id, user_id: @user_id)
    return failure("That reminder doesn't exist.") unless reminder

    transaction { reminder.destroy! }
    ok(reminder)
  end
end
