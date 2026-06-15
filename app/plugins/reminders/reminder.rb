module Reminders
  # A scheduled reminder. Keyed by raw Discord snowflakes (no local FKs):
  # server_id is null for DM reminders. Delivery is handled by DeliverJob.
  class Reminder < ApplicationRecord
    # Namespaced model → set the table explicitly (the demodulized default would
    # also be "reminders", but be unambiguous).
    self.table_name = "reminders"

    validates :user_id, :channel_id, :remind_at, :message, presence: true

    scope :for_user, ->(user_id) { where(user_id:).order(:remind_at) }
  end
end
