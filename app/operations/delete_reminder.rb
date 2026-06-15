# Deletes a reminder, scoped to its owner so a user can't cancel someone else's.
# No job cancellation needed — DeliverJob guards on row existence, so a deleted
# reminder simply no-ops when its job fires.
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
