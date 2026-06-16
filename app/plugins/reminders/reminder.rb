module Reminders
  # Scheduled reminders keyed by Discord snowflakes. Delivery handled by DeliverJob;
  # server_id is null for DM reminders.
  class Reminder < ApplicationRecord
    # Explicit table name to avoid ambiguity with demodulized default.
    self.table_name = "reminders"

    validates :user_id, :channel_id, :remind_at, :message, presence: true

    scope :for_user, ->(user_id) { where(user_id:).order(:remind_at) }
  end
end
